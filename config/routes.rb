Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "/show/:gid", :to => "maps#show"
  namespace :api, {format: 'json'} do
    namespace :v1 do
      namespace :application do
        get "/0", :action => "index"
        post "/registration", :action => "registration"
        get "/:id", :action => "show_location"
        post "/:id", :action => "update_location"
      end
    end
    namespace :v2 do
      namespace :application do
        get "/register",           :action => "register_make_group"
        get "/refPoint/:uid",      :action => "make_group"
        get "/register/:gid",      :action => "register_access_to_group"
        get "/refPoint/:gid/:uid", :action => "update_reference_point"
        get "/notify/:gid/:uid",   :action => "notify_signal_to_group_member"
        get "/shareReed/:gid/:uid/:arrData",   :action => "notify_signal_to_group_member_with_data"
        get "/routelog/:gid",      :action => "get_log_of_the_group"
      end
    end
  end
end
