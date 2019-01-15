class Map::MapsController < ApplicationController
  def show
    @log = RouteLog.where(:group_id => @group.id)
    render json: @log
end
