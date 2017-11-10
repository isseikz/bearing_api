Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api, {format: 'json'} do
    namespace :v1 do
      namespace :application do
        get "/", :action => "index"
      end
    end
  end
end
