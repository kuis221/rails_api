Brandscopic::Application.routes.draw do
  apipie

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post 'sessions' => 'sessions#create'
        delete 'sessions' => 'sessions#destroy'

        get '/companies' => 'users#companies'
        resources :users, only: [:index, :update] do
          collection do
            match 'password/new_password', to: 'users#new_password', via: :post
            get :permissions
          end
        end

        resources :events, only: [:index, :show, :create, :update] do
          resources :photos, only: [:index, :create, :update]
          resources :event_expenses, only: [:index, :create]
          resources :tasks, only: [:index]
          resources :comments, only: [:index, :create]
          resources :surveys, only: [:index, :create]
          member do
            get :results
            get :members
            post :members, to: "events#add_member"
            get :assignable_members
            get :contacts
            post :contacts, to: "events#add_contact"
            get :assignable_contacts
          end
        end
        # To allow CORS for any API action
        match ':path1(/:path2(/:path3))', via: :options, to: 'api#options'

        resources :campaigns, only: [] do
          get :all, on: :collection
        end

        resources :venues, only: [:index, :show] do
          get :search, on: :collection
          member do
            get :photos
          end
        end

        resources :countries, only: [:index] do
          get :states, on: :member
        end

        resources :contacts, only: [:index, :create, :update]

        resources :tasks, only: [] do
          member do
            get :comments
          end
          collection do
            get :mine, to: :index, :defaults => {:scope => "user"}, :constraints => { :scope => 'user' }
            get :team, to: :index, :defaults => {:scope => "teams"}, :constraints => { :scope => 'teams' }
          end
        end
      end
    end
  end

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount Resque::Server.new, :at => '/resque'

  devise_for :users, :controllers => { :invitations => 'invitations', :passwords => "passwords" }

  devise_scope :user do
    put '/users/confirmation', to: 'confirmations#update'
    get '/users/invitation/resend', to: 'invitations#resend'
    post '/users/invitation/resend', to: 'invitations#send_invite'
    get "/users/password/thanks", to: 'passwords#thanks', as: :passwords_thanks
  end

  get '/users/complete-profile', to: 'users#complete', as: :complete_profile
  put '/users/update-profile', to: 'users#update_profile', as: :update_profile

  get 'select-company/:company_id', to: 'company_users#select_company', as: :select_company, constraints: {company_id: /[0-9]+/}

  get "countries/states"

  get "/notifications", to: 'company_users#notifications', format: :json

  get 'exports/:download_id/status', to: 'company_users#export_status', as: :export_status, format: :json

  resources :goals, only: [:create, :update]

  namespace :results do
    resources :event_data, only: [:index] do
      get :items, on: :collection
    end
    resources :comments, only: [:index] do
      get :items, on: :collection
    end
    resources :photos, only: [:index] do
      get :items, on: :collection
      get :autocomplete, on: :collection
      get :filters, on: :collection
      post 'downloads', to: 'photos#new_download', on: :collection, format: :js
      get 'downloads/:download_id', to: 'photos#download', on: :collection, as: :download, format: :js
      get 'downloads/:download_id/status', to: 'photos#download_status', on: :collection, as: :download_status, format: :json
    end
    resources :expenses, only: [:index] do
      get :items, on: :collection
    end
    resources :surveys, only: [:index] do
      get :items, on: :collection
    end
    get :gva, to: 'gva#index'
    post :gva, to: 'gva#report'

    resources :reports, only: [:index, :new, :create, :edit, :update]

    # For The KPI report
    get :kpi_report, to: 'kpi_report#index'
    post :kpi_report, to: 'kpi_report#report'
    get :kpi_report_status, to: 'kpi_report#status'
  end

  namespace :analysis do
    get :campaigns_report, to: 'campaigns_report#index'
    post :campaigns_report, to: 'campaigns_report#report'

    get :staff_report, to: 'staff_report#index'
    post :staff_report, to: 'staff_report#report'
  end

  # This couple of routes are for tasks
  get ":controller/:scope/filters", format: :json, as: :filters
  get ":controller/:scope/items", format: :html, as: :items

  get ":controller/filters", format: :json, as: :filters
  get ":controller/items", format: :html, as: :items

  scope "/research" do
    resources :venues, only: [:index, :show] do
      member do
        match 'areas/:area_id' => 'venues#delete_area', via: :delete, as: :delete_area
        match 'areas/select' => 'venues#select_areas', via: :get, as: :select_areas
        match 'areas/add' => 'venues#add_areas', via: :post, as: :add_area
        match 'areas' => 'venues#areas', via: :get, as: :areas
      end
      resources :events, only: [:new, :create]
    end
  end

  resources :roles do
    get :autocomplete, on: :collection
    member do
      get :deactivate
      get :activate
    end
  end

  resources :company_users, except: [:new, :create, :destroy], path: 'users' do
    get :autocomplete, on: :collection
    get :time_zone_change, on: :collection
    post :time_zone_change, on: :collection
    put :time_zone_update, on: :collection
    get :event, via: :get, on: :collection # List of users by event
    resources :placeables, only: [:new] do
      post :add_area, on: :collection
      delete :remove_area, on: :collection
    end
    resources :places, only: [:destroy, :create]
    resources :goals, only: [:create, :update, :edit, :new]
    resources :tasks do
      member do
        get :deactivate
        get :activate
      end
    end
    member do
      get :deactivate
      get :activate
      post :enable_campaigns
      post :disable_campaigns
      get :select_campaigns
      delete :remove_campaign
      post :add_campaign
    end
  end

  resources :teams do
    get :autocomplete, on: :collection
    member do
      get :deactivate
      get :activate
      match 'members/:member_id' => 'teams#delete_member', via: :delete, as: :delete_member
      match 'members/new' => 'teams#new_member', via: :get, as: :new_member
      match 'members' => 'teams#add_members', via: :post, as: :add_member
    end
  end

  resources :campaigns do
    resources :brands, only: [:index]
    resources :kpis, only: [:new, :create, :edit, :update]
    resources :placeables, only: [:new] do
      post :add_area, on: :collection
      delete :remove_area, on: :collection
    end
    resources :places, only: [:destroy, :create]
    get :autocomplete, on: :collection
    get :find_similar_kpi, on: :collection
    member do
      get :post_event_form
      post :update_post_event_form
      post :kpi, to: :add_kpi
      delete :kpi, to: :remove_kpi
      get :deactivate
      get :activate
      get :kpis
      get :places
      match 'members/:member_id' => 'campaigns#delete_member', via: :delete, as: :delete_member
      match 'teams/:team_id' => 'campaigns#delete_member', via: :delete, as: :delete_team
      match 'members/new' => 'campaigns#new_member', via: :get, as: :new_member
      match 'members' => 'campaigns#add_members', via: :post, as: :add_member
      match 'members' => 'campaigns#members', via: :get, as: :members
      match 'teams' => 'campaigns#teams', via: :get, as: :teams
      match 'tab/:tab' => 'campaigns#tab', via: :get, as: :tab, constraints: {tab: /staff|places|date_ranges|day_parts|documents/}

      match 'date_ranges/new' => 'campaigns#new_date_range', via: :get, as: :new_date_range
      match 'date_ranges' => 'campaigns#add_date_range', via: :post, as: :add_date_range
      match 'date_ranges/:date_range_id' => 'campaigns#delete_date_range', via: :delete, as: :delete_date_range

      match 'day_parts/new' => 'campaigns#new_day_part', via: :get, as: :new_day_part
      match 'day_parts' => 'campaigns#add_day_part', via: :post, as: :add_day_part
      match 'day_parts/:day_part_id' => 'campaigns#delete_day_part', via: :delete, as: :delete_day_part
    end

    resources :documents, only: [:create, :new] do
      member do
        get :deactivate
        get :activate
      end
    end
  end

  resources :events do
    get :autocomplete, on: :collection
    get :calendar, on: :collection
    get :tasks, on: :member
    get :edit_data, on: :member
    get :edit_surveys, on: :member
    get :calendar_dates, on: :collection, to: :calendar_highlights
    resources :tasks, only: [:create, :new] do
      member do
        get :deactivate
        get :activate
      end
    end

    resources :surveys, only: [:create, :new, :edit, :update] do
      member do
        get :deactivate
        get :activate
      end
    end

    resources :documents, only: [:create, :new] do
      member do
        get :deactivate
        get :activate
      end
    end

    resources :photos, only: [:create, :new] do
      get :processing_status, on: :collection
      member do
        get :deactivate
        get :activate
      end
    end

    resources :comments, only: [:create, :new, :destroy, :edit, :update]
    resources :event_expenses, only: [:create, :new, :destroy, :edit, :update]

    resources :contact_events, path: :contacts, only: [:create, :new, :destroy, :edit, :update] do
      get 'add', on: :collection
      get 'list', on: :collection
    end

    member do
      get :deactivate
      get :activate
      put :submit
      put :approve
      put :reject
      match 'members/:member_id' => 'events#delete_member', via: :delete, as: :delete_member
      match 'teams/:team_id' => 'events#delete_member', via: :delete, as: :delete_team
      match 'members/new' => 'events#new_member', via: :get, as: :new_member
      match 'members' => 'events#add_members', via: :post, as: :add_member
    end
  end

  resources :tasks, only: [:new, :create, :edit, :update] do
    collection do
      get :autocomplete
      get :mine, to: :index, :defaults => {:scope => "user"}, :constraints => { :scope => 'user' }
      get :my_teams, to: :index, :defaults => {:scope => "teams"}, :constraints => { :scope => 'teams' }
    end
    member do
      get :deactivate
      get :activate
    end
    resources :comments, only: [:create, :index]
  end

  resources :brand_portfolios do
    get :autocomplete, on: :collection
    resources :brands, only: [:new, :create]
    member do
      get :deactivate
      get :activate
      match 'brands/:brand_id' => 'brand_portfolios#delete_brand', via: :delete, as: :delete_brand
      match 'brands/select' => 'brand_portfolios#select_brands', via: :get, as: :select_brands
      match 'brands/add' => 'brand_portfolios#add_brands', via: :post, as: :add_brand
      match 'brands' => 'brand_portfolios#brands', via: :get, as: :brands
    end
  end

  resources :brands, only: [:index]

  resources :areas do
    get :autocomplete, on: :collection
    resources :places, only: [:new, :create, :destroy]
    member do
      get :deactivate
      get :activate
    end
  end

  resources :places, only: [:create, :new] do
    get :search, format: :json, on: :collection
    resources :areas, only: [:new, :create]
  end

  resources :date_ranges do
    get :autocomplete, on: :collection
    resources :date_items, path: 'dates', only: [:new, :create, :destroy]
    member do
      get :deactivate
      get :activate
    end
  end

  resources :day_parts do
    get :autocomplete, on: :collection
    resources :day_items, path: 'days', only: [:new, :create, :destroy]
    member do
      get :deactivate
      get :activate
    end
  end

  root :to => 'dashboard#index'
end
