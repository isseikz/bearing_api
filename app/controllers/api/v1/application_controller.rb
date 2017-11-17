class Api::V1::ApplicationController < ActionController::API
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

  def registration
    loc = Location.new
    loc.longitude = params[:lon]
    loc.lattitude = params[:lat]
    loc.bearing = params[:bea]
    loc.speed = params[:spd]
    loc.save
    render json: getLocationHash(loc)
  end

  def show_location
    loc = Location.find(params[:id])
    render json: getLocationHash(loc)
  end

  def update_location
    loc = Location.find(params[:id])
    loc.longitude = params[:lon]
    loc.lattitude = params[:lat]
    loc.bearing = params[:bea]
    loc.speed = params[:spd]
    loc.save
    render json: getLocationHash(Location.find(params[:id]))

  end

  def getLocationHash(loc)
    @location =
    {
      id: loc.id,
      longitude: loc.longitude,
      latitude:  loc.lattitude,
      bearing:   loc.bearing,
      speed:     loc.speed
    }
    return @location
  end
end
