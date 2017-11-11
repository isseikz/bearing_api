Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api, {format: 'json'} do
    namespace :v1 do
      namespace :application do
        get "/0", :action => "index"
        post "/registration", :action => "registration"
        get "/:id", :action => "show_location"
        post "/:id", :action => "update_location"
      end
    end
  end

end
