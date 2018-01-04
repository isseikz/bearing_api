require 'andpush'

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
    end

    # 各ユーザの平均位置を目標点に設定した
    numberOfMembers = @group.group_users.length
    puts(@user.latitude)
    puts(@user.longitude)
    puts(@group.reference_latitude)
    puts(@group.reference_longitude)
    @group.reference_latitude  = (@group.reference_latitude * numberOfMembers + @user.latitude  - past_latitude) / numberOfMembers
    @group.reference_longitude = (@group.reference_longitude * numberOfMembers + @user.longitude - past_longitude) / numberOfMembers
    puts(@group.reference_latitude)
    puts(@group.reference_longitude)
    @group.save
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
