class Api::V1::ApplicationController < ActionController::API
  def index
    @testLocation =
    {
      id: 0,
      longitude: 139.12345,
      lattitude: 35.12345,
    }
    render json: @testLocation
  end
end
