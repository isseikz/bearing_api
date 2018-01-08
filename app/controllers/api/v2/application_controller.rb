require 'andpush'

require 'json'
require 'uri'
require 'net/https'

class Api::V2::ApplicationController < ActionController::API
  def index
    @testLocation =
    {
      id: 0,
      longitude: 123.45678,
      latitude: 12.35813,
      bearing: 24.680,
      speed: 1.3579
    }
    render json: @testLocation
  end

  # 役割：ユーザIDのない端末にユーザID、グループIDを付与する
  # 入力：緯度(lat),経度(lon),速さ
  # 出力：ユーザID(uid),グループID(gid)
  def register_make_group
    @new_user = User.new
    @new_user.token     = params[:token] #Push通知用トークン
    @new_user.latitude  = params[:lat]   #経度
    @new_user.longitude = params[:lon]   #緯度
    @new_user.speed     = params[:spd]   #速さ
    @new_user.bearing   = params[:bea]   #進行方向

    if !@new_user.save
      render :text => "User Validation Error",  :status => 500
      return
    end

    @new_group = Group.new
    @new_group.reference_latitude  = params[:lat]
    @new_group.reference_longitude = params[:lon]
    if !@new_group.save
      render :text => "Group Validation Error", :status => 500
      return
    end

    @group_user = GroupUser.new
    @group_user.user_id  = @new_user.id
    @group_user.group_id = @new_group.id
    if !@group_user.save
      render :text => "GroupUser Relation Error", :status => 500
      return
    else
      render json: @group_user
    end
  end

  # 役割：ユーザIDのある端末にグループIDを付与する
  # 入力：緯度(lat),経度(lon),ユーザID(uid)
  # 出力：グループID(gid)
  def make_group
    @user = User.find(params[:uid])
    @user.latitude  = params[:lat]
    @user.longitude = params[:lon]
    @user.speed     = params[:spd]
    @user.bearing   = params[:bea]
    if params.has_value?(:token)
      @user.token = params[:token]
    end
    @user.save

    @new_group = Group.new
    @new_group.reference_latitude  = params[:lat]
    @new_group.reference_longitude = params[:lon]
    if !@new_group.save
      render :text => "Group Validation Error", :status => 500
      return
    end

    @group_user = GroupUser.new
    @group_user.user_id  = @user.id
    @group_user.group_id = @new_group.id
    if !@group_user.save
      render :text => "GroupUser Relation Error", :status => 500
      return
    else
      render json: @group_user
    end
  end

  # 役割：ユーザIDのない端末をグループに接続する
  # 入力：緯度(lat),経度(lon),グループID(gid)
  # 出力：ユーザID(uid)
  def register_access_to_group
    @new_user = User.new
    @new_user.token     = params[:token]     #Push通知用トークン
    @new_user.latitude  = params[:lat]       #経度
    @new_user.longitude = params[:lon]       #緯度
    @new_user.speed     = params[:spd]     #速さ
    @new_user.bearing   = params[:bea]   #進行方向

    if !@new_user.save
      render :text => "User Validation Error",  :status => 500
      return
    end

    @group = Group.find(params[:gid])

    @group_user = GroupUser.new
    @group_user.user_id = @new_user.id
    @group_user.group_id = @group.id
    if !@group_user.save
      render :text => "GroupUser Relation Error", :status => 500
      return
    else
      render json: @group_user
    end
  end

  # 役割：ユーザID,グループIDを照合して目標位置を更新する
  # 入力：緯度(lon),経度(lat),グループID(gid),ユーザID(uid)
  # 出力：目標緯度(lat),目標経度(lon)
  def update_reference_point
    @user = User.find(params[:uid])
    past_latitude   = @user.latitude
    past_longitude  = @user.longitude
    @user.latitude  = params[:lat]
    @user.longitude = params[:lon]
    @user.speed     = params[:spd]
    @user.bearing   = params[:bea]
    @user.token     = params[:token]
    @user.save

    @group = Group.find(params[:gid])

    # グループに存在しなければ追加
    if !@group.group_users.exists?(:user_id => @user.id)
      @group_user = GroupUser.new
      @group_user.group_id = @group.id
      @group_user.user_id  = @user.id
      @group_user.save
      flag_add_new_user = true
    else
      flag_add_new_user = false
    end

    @log = RouteLog.new
    @log.user_id = @user.id
    @log.group_id = @group.id
    @log.latitude = @user.latitude
    @log.longitude = @user.longitude
    @log.speed = @user.speed
    @log.bearing = @user.bearing
    @log.save


    # TODO 目標点(待ち合わせ場所)の決定方法
    # 他のユーザとの距離を調べる
    # 距離が一定値以下？
      # 一定値以下なら、近隣ユーザモデルに該当データがあるか検索
        # データは存在したか？
          # 存在したら、uid1→uid2の経路をAPIで検索する
          # 存在しなかったら、リクエストユーザ→他ユーザの経路をAPIで検索する
        # WayPointの配列をレスポンスとして受け取る
        # uid1,uid2,配列の中央値を近隣ユーザモデルに保存

      # 一定値以上なら、何もせず次のユーザとの距離を計算
    haveUserAroundMe = false
    meeting_latitude  = 0.0
    meeting_longitude = 0.0

    @group.group_users.each{ |group_user|
      another_user = group_user.user
      if group_user.user_id != @user.id
        puts("Calc distance...")
        distance = (another_user.latitude - @user.latitude) ** 2 + (another_user.longitude - @user.longitude) ** 2
        printf('distance: %.10f \n', distance)
        if distance <= (0.00100 ** 2) && distance >= (0.00010 ** 2) # 条件：だいたい100[m]以下、10[m]以上(近すぎならと合流したとみなす)
          haveUserAroundMe = true

          puts('near')
            if UserAroundMe.find_by(:user1_id => another_user.id, :user2_id => @user.id)
              # TODO uid1→uid2の経路をAPIで検索するurlを生成
              search_params = 'origin=' + another_user.latitude.to_s + ',' + another_user.longitude.to_s + '&destination=' + @user.latitude.to_s + ',' + @user.longitude.to_s
            elsif UserAroundMe.find_by(:user2_id => @user.id,:user1_id => another_user.id)
              # TODO リクエストユーザ→他ユーザの経路をAPIで検索するurlを生成
              search_params = 'origin=' + @user.latitude.to_s + ',' + @user.longitude.to_s + '&destination=' + another_user.latitude.to_s + ',' + another_user.longitude.to_s
            else
              @userAroudMe = UserAroundMe.new
              @userAroudMe.user1_id = @user.id
              @userAroudMe.user2_id =  another_user.id
              @userAroudMe.save
              search_params = 'origin=' + @user.latitude.to_s + ',' + @user.longitude.to_s + '&destination=' + another_user.latitude.to_s + ',' + another_user.longitude.to_s
            end
            common_params = "&mode=walking&key=AIzaSyAz6oV0_57kPlmxfcP2TZ2oJXAO9d3mAzw"
            url = 'https://maps.googleapis.com/maps/api/directions/json?' + search_params + common_params
            puts(url)

            # TODO 上述のurlで経路を検索してJSONのレスポンスを受け取る
            uri = URI.parse(url)
            response = Net::HTTP.get(uri)
            puts(response)
            json = JSON.parse(response)
            hash_routes = json["routes"][0]
            puts(hash_routes)
            hash_legs = hash_routes["legs"][0]
            puts(hash_legs)
            hash_steps = hash_legs["steps"]
            puts(hash_steps)
            hash_end_location = hash_legs["end_location"]
            puts(hash_end_location)

            meeting_latitude  = hash_end_location["lat"].to_f
            meeting_longitude = hash_end_location["lng"].to_f
        end
      end
    }


    # 各ユーザの平均位置を目標点に設定した
    numberOfMembers = @group.group_users.length
    puts(numberOfMembers)
    puts(@user.id)
    puts(@user.latitude)
    puts(@user.longitude)
    puts(past_latitude)
    puts(past_longitude)
    puts(@group.reference_latitude)
    puts(@group.reference_longitude)

    if flag_add_new_user
      @group.reference_latitude  = (@group.reference_latitude  * (numberOfMembers-1) + @user.latitude ) / numberOfMembers
      @group.reference_longitude = (@group.reference_longitude * (numberOfMembers-1) + @user.longitude) / numberOfMembers
    else
      @group.reference_latitude  = (@group.reference_latitude * numberOfMembers + @user.latitude  - past_latitude) / numberOfMembers
      @group.reference_longitude = (@group.reference_longitude * numberOfMembers + @user.longitude - past_longitude) / numberOfMembers
    end
    @group.save

    # 近くにユーザがいるときはその人と合流することを優先する
    # 全体の目標位置ではないため、保存はしない
    if haveUserAroundMe
      @group.reference_latitude  = meeting_latitude
      @group.reference_longitude = meeting_longitude
    end

    puts(@group.reference_latitude)
    puts(@group.reference_longitude)
    render json: @group
    # if !@group.save
    #   render :text => "Reference point updating Error", :status => 500
    #   return
    # else
    #   render json: @group
    # end
  end

  def notify_signal_to_group_member
    puts('notify')
    server_key = "AAAA210pqpM:APA91bFfAogCaB2xesRHJXPzSSaxFyC1X19m9ggy6bA5_fB9yoAqZ1Mzd3-kqjA3JrjJgXefqZm4SrAcGEIotCFNapOl0qBjy0Dtnz6L1FhO8XxWTQGIQ-ZmFHgcmumdLRRlol_Ld25m"

    @group = Group.find(params[:gid])
    @group_users = @group.group_users
    @group_users.each { |e|
        user_token = e.user.token
        puts(user_token)

        client = Andpush.build(server_key)
        payload = {
          to: user_token,
          data: {
            extra: "data"
          }
        }

        response = client.push(payload)
        json = response.json

        puts(json[:canonical_ids])
        puts(json[:failure])
        puts(json[:multicast_id])

        result = json[:results].first
        puts(result[:message_id])
        puts(result[:error])
        puts(result[:registration_id])
      }

  end

end
