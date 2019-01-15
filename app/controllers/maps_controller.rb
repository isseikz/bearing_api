class MapsController < ApplicationController
  def show
    @log = RouteLog.where(:group_id => params[:gid])
   # render json: @log
  end
end
