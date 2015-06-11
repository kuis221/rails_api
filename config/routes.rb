Brandscopic::Application.routes.draw do

  mount Nkss::Engine => '/styleguides' if Rails.env.development?
  apipie if ENV['WEB']

  # Redirect old urls to new ones
  get '/results/gva', to: redirect('/analysis/gva')
  get '/results/event_status', to: redirect('/analysis/event_status')
  get '/results/attendance', to: redirect('/analysis/attendance')

  concern :deactivatable do
    get :deactivate, on: :member
    get :activate, on: :member
  end

  concern :filterable do
    get :items, on: :collection, format: :html
  end

  concern :api_attachable do
    get :form, on: :collection
  end

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post 'sessions' => 'sessions#create'
        delete 'sessions' => 'sessions#destroy'

        get '/companies' => 'users#companies'
        resources :users, only: [:index, :update, :show] do
          collection do
            match 'password/new_password', to: 'users#new_password', via: :post
            get :permissions
            get :notifications
          end
        end
        resources :activities, only: [:new, :show]

        resources :filters, only: [:show]

        resources :events, only: [:index, :show, :create, :update] do
          get :status_facets, on: :collection
          get :requiring_attention, on: :collection
          post :filter, to: 'events#index', on: :collection
          resources :photos, only: [:index, :create, :update], concerns: [:api_attachable]
          resources :documents, only: [:index, :create, :update], concerns: [:api_attachable]
          resources :event_expenses, only: [:index, :create, :destroy], concerns: [:api_attachable]
          resources :tasks, only: [:index]
          resources :comments, only: [:index, :create, :update, :destroy]
          resources :surveys,  only: [:index, :create, :update, :show] do
            get :brands, on: :collection
          end
          resources :invites, only: [:index, :show, :create, :update]
          resources :activities, only: [:index, :create, :update], concerns: [:deactivatable] do
            get :deactivate, on: :member
          end
          get :autocomplete,   on: :collection
          member do
            put :submit
            put :reject
            put :approve
            get :results
            get :members
            post :members, to: 'events#add_member'
            delete :members, to: 'events#delete_member'
            get :assignable_members
            get :contacts
            post :contacts, to: 'events#add_contact'
            delete :contacts, to: 'events#delete_contact'
            get :assignable_contacts
          end
        end

        resources :campaigns, only: [] do
          collection do
            get :all
            get :overall_stats
          end
          resources :activity_types, only: [:index]
          resources :brands, only: [:index]
          get :stats, on: :member
          get :events, on: :member
          get :expense_categories, on: :member
        end

        resources :activity_types, only: [:index] do
          member do
            get :campaigns
          end
        end

        resources :venues, only: [:index, :show, :create] do
          get :search, on: :collection
          get :types, on: :collection
          get :autocomplete, on: :collection
          resources :invites, only: [:index, :show, :create, :update]
          resources :activities, only: [:index, :create, :update] do
            get :deactivate, on: :member
          end
          member do
            get :analysis
            get :photos
            get :comments
          end
        end

        resources :areas, only: [:index] do
          get :cities, on: :member
        end

        resources :brands, only: [:index] do
          get :marques, on: :member
        end

        resources :countries, only: [:index] do
          get :states, on: :member
        end

        resources :contacts, only: [:index, :create, :update, :show]

        resources :tasks, only: [] do
          member do
            get :comments
          end
          collection do
            get :mine, to: :index, defaults: { scope: 'user' }, constraints: { scope: 'user' }
            get :team, to: :index, defaults: { scope: 'teams' }, constraints: { scope: 'teams' }
          end
        end

        namespace :brand_ambassadors do
          resources :visits, only: [:index, :create, :update, :show] do
            get :types, on: :collection
            get :events, on: :member
          end
          resources :documents, only: [:create, :update, :destroy, :index]
        end
      end
    end
  end

  if ENV['WEB']
    devise_for :admin_users, ActiveAdmin::Devise.config
    ActiveAdmin.routes(self)

    mount Resque::Server.new, at: '/resque' unless Rails.env.test?
  end

  devise_for :users, controllers: { invitations: 'invitations', passwords: 'passwords' }

  devise_scope :user do
    put '/users/confirmation', to: 'confirmations#update'
    get '/users/invitation/resend', to: 'invitations#resend'
    get '/users/invitation/renew', to: 'invitations#renew'
    post '/users/invitation/resend', to: 'invitations#send_invite'
    get '/users/password/thanks', to: 'passwords#thanks', as: :passwords_thanks
  end

  put '/users/dismiss_alert', to: 'company_users#dismiss_alert'

  get 'select-company/:company_id', to: 'company_users#select_company', as: :select_company, constraints: { company_id: /[0-9]+/ }
  put 'login-as', to: 'company_users#select_custom_user', as: :select_custom_user

  resources :countries, only: [] do
    get :states, on: :collection
    get :cities, on: :member
  end

  get '/notifications.json', to: 'company_users#notifications', format: :json

  get 'exports/:download_id/status', to: 'company_users#export_status', as: :export_status, format: :json

  resources :goals, only: [:create, :update]

  resources :photos, only: [:show]

  # /filters/events /filters/campaigns etc
  resources :filters, only: [:show] do
    get :expand, on: :collection
  end

  # /autocomplete/events /autocomplete/campaigns etc
  resources :autocomplete, only: [:show]

  namespace :results do
    resources :event_data, only: [:index], concerns: [:filterable]
    resources :comments, only: [:index], concerns: [:filterable]
    resources :photos, only: [:index], concerns: [:filterable] do
      post 'downloads', to: 'photos#new_download', on: :collection, format: :js
      get 'downloads/:download_id', to: 'photos#download', on: :collection, as: :download, format: :js
      get 'downloads/:download_id/status', to: 'photos#download_status', on: :collection, as: :download_status, format: :json
    end
    resources :activities, only: [:index], concerns: [:filterable]
    resources :expenses, only: [:index], concerns: [:filterable]
    resources :surveys, only: [:index], concerns: [:filterable]

    # resources :attendance, only: [:index] do
    # end

    resources :reports, only: [:index, :new, :create, :edit, :update, :show],
                        concerns: [:deactivatable] do
      get :build, on: :member
      get :rows, on: :member
      get :filters, on: :member
      get :share, to: 'reports#share_form', on: :member
      post :preview, on: :member
    end

    resources :data_extracts, only: [:new, :create, :show, :edit, :update] do
      get :preview, on: :collection
      get :save, on: :collection
      get :available_fields, on: :collection
      get :items, on: :collection
      get :deactivate, on: :member
      get :activate, on: :member
    end

    # For The KPI report
    get :kpi_report, to: 'kpi_reports#index'

    post :kpi_report, to: 'kpi_reports#report'
    get :kpi_report_status, to: 'kpi_reports#status'

  end

  namespace :analysis do
    resources :trends, only: [] do
      collection do
        get :sources
        get :questions
        get :results
        get :items
        get :filters
        get :search
      end
      get 't/:term', on: :collection, to: :show
      get 't/:term/:action', on: :collection
    end

    get 'attendance/map', to: 'attendance#map', as: :attendance_map
    get 'attendance', to: 'attendance#index', as: :attendance

    get :gva, to: 'gva#index'
    post :gva, to: 'gva#report'
    get :report_groups, to: 'gva#report_groups'

    get :event_status, to: 'event_status#index'
    post :event_status, to: 'event_status#report'

    get :campaigns_report, to: 'campaigns_report#index'
    post :campaigns_report, to: 'campaigns_report#report'

    get :staff_report, to: 'staff_report#index'
    post :staff_report, to: 'staff_report#report'

    get '/', to: 'analysis#index'
  end

  scope '/research' do
    resources :venues, only: [:index, :show], concerns: [:filterable] do
      member do
        match 'areas/:area_id' => 'venues#delete_area', via: :delete, as: :delete_area
        match 'areas/select' => 'venues#select_areas', via: :get, as: :select_areas
        match 'areas/add' => 'venues#add_areas', via: :post, as: :add_area
        match 'areas' => 'venues#areas', via: :get, as: :areas
      end
      resources :events, only: [:new, :create]
      resources :invites, only: [:create, :edit, :update, :index], concerns: [:deactivatable]
      resources :activities, only: [:new, :create] do
        get :thanks, on: :collection
        get :form, on: :collection
        get :empty_form, to: 'activities#export_empty_fieldable', on: :collection
      end
    end
  end

  resources :roles, except: [:destroy], concerns: [:deactivatable, :filterable]

  resources :company_users, except: [:new, :create, :destroy], path: 'users', concerns: [:deactivatable, :filterable] do
    get :profile, on: :collection
    get :time_zone_change, on: :collection
    get :resend_email_confirmation, on: :member
    get :cancel_email_change, on: :member
    post :time_zone_change, on: :collection
    put :time_zone_update, on: :collection
    get :login_as_select, on: :collection
    resources :places, only: [:destroy, :create]
    resources :goals, only: [:create, :update, :edit, :new]
    resources :tasks, concerns: [:deactivatable]
    member do
      post :verify_phone
      get :send_code
      get :resend_invite
      post :enable_campaigns
      post :disable_campaigns
      get :select_campaigns
      delete :remove_campaign
      post :add_campaign
      get :edit_communications
    end
  end

  resources :teams, except: [:destroy], concerns: [:deactivatable, :filterable] do
    member do
      match 'members/:member_id' => 'teams#delete_member', via: :delete, as: :delete_member
      match 'members/new' => 'teams#new_member', via: :get, as: :new_member
      match 'members' => 'teams#add_members', via: :post, as: :add_member
    end
  end

  resources :kpis, only: [:index]

  resources :campaigns, except: [:destroy], concerns: [:deactivatable, :filterable] do
    resources :areas_campaigns, only: [:edit, :update] do
      post :exclude_place, on: :member
      post :include_place, on: :member
      get :new_place, on: :member
      post :add_place, on: :member
    end

    resources :brands, only: [:index]
    resources :kpis, only: [:new, :create, :edit, :update]
    resources :activity_types, only: [] do
      get :set_goal
    end
    resources :places, only: [:destroy, :create]
    get :find_similar_kpi, on: :collection
    member do
      get :post_event_form
      post :update_post_event_form
      get :places
      get :event_dates
      get :form, to: 'campaigns#export_fieldable'
      match 'members/:member_id' => 'campaigns#delete_member', via: :delete, as: :delete_member
      match 'teams/:team_id' => 'campaigns#delete_member', via: :delete, as: :delete_team
      match 'members/new' => 'campaigns#new_member', via: :get, as: :new_member
      match 'members' => 'campaigns#add_members', via: :post, as: :add_member
      match 'members' => 'campaigns#members', via: :get, as: :members
      match 'teams' => 'campaigns#teams', via: :get, as: :teams
      match 'tab/:tab' => 'campaigns#tab', via: :get, as: :tab, constraints: { tab: /staff|places|date_ranges|day_parts|documents|kpis/ }

      match 'date_ranges/new' => 'campaigns#new_date_range', via: :get, as: :new_date_range
      match 'date_ranges' => 'campaigns#add_date_range', via: :post, as: :add_date_range
      match 'date_ranges/:date_range_id' => 'campaigns#delete_date_range', via: :delete, as: :delete_date_range

      match 'day_parts/new' => 'campaigns#new_day_part', via: :get, as: :new_day_part
      match 'day_parts' => 'campaigns#add_day_part', via: :post, as: :add_day_part
      match 'day_parts/:day_part_id' => 'campaigns#delete_day_part', via: :delete, as: :delete_day_part

      match 'kpis/select' => 'campaigns#select_kpis', via: :get, as: :select_kpis
      match 'kpis/add' => 'campaigns#add_kpi', via: :post, as: :add_kpi
      match 'kpis/:kpi_id' => 'campaigns#remove_kpi', via: :delete, as: :remove_kpi

      match 'activity_types/add' => 'campaigns#add_activity_type', via: :post, as: :add_activity_type
      match 'activity_types/:activity_type_id' => 'campaigns#remove_activity_type', via: :delete, as: :remove_activity_type
    end

    resources :documents, only: [:create], concerns: [:deactivatable]
  end

  resources :events, except: [:destroy], concerns: [:deactivatable, :filterable] do
    get ':phase', to: 'events#show', on: :member,
                  as: :phase, constraints: { phase: /plan|execute|results/ }
    get :map, on: :collection, format: :json

    get :calendar, on: :collection
    get :edit_data, on: :member
    get :edit_surveys, on: :member
    get :calendar_dates, on: :collection, to: :calendar_highlights
    resources :tasks, only: [:create, :new], concerns: [:deactivatable]

    resources :invites, only: [:create, :edit, :update, :index], concerns: [:deactivatable]

    resources :surveys, only: [:create, :new, :edit, :update], concerns: [:deactivatable]

    resources :documents, only: [:create], concerns: [:deactivatable]

    resources :photos, only: [:create, :new], concerns: [:deactivatable] do
      get :processing_status, on: :collection
    end

    resources :comments, only: [:create, :new, :destroy, :edit, :update]
    resources :event_expenses, only: [:create, :new, :destroy, :edit, :update] do
      post :split, on: :collection
    end

    resources :contact_events, path: :contacts, only: [:create, :new, :destroy, :edit, :update] do
      get 'add', on: :collection
      get 'list', on: :collection
    end

    resources :activities, only: [:new, :create] do
      get :thanks, on: :collection
    end

    member do
      put :submit
      put :approve
      put :unapprove
      put :reject
      get :form, to: 'events#export_fieldable'
      match 'members/:member_id' => 'events#delete_member', via: :delete, as: :delete_member
      match 'teams/:team_id' => 'events#delete_member', via: :delete, as: :delete_team
      match 'members/new' => 'events#new_member', via: :get, as: :new_member
      match 'members' => 'events#add_members', via: :post, as: :add_member
    end
  end

  resources :tasks, only: [:new, :create, :edit, :update], concerns: [:deactivatable] do
    collection do
      get ':scope/items', to: 'tasks#items', constraints: { scope: /user|teams/ }, format: :json

      get :mine, to: :index, defaults: { scope: 'user' }, constraints: { scope: 'user' }
      get :my_teams, to: :index, defaults: { scope: 'teams' }, constraints: { scope: 'teams' }
    end
    resources :comments, only: [:create, :index]
  end

  resources :brand_portfolios, except: [:destroy], concerns: [:deactivatable, :filterable] do
    resources :brands, only: [:new, :create]
    member do
      match 'brands/:brand_id' => 'brand_portfolios#delete_brand', via: :delete, as: :delete_brand
      match 'brands/select' => 'brand_portfolios#select_brands', via: :get, as: :select_brands
      match 'brands/add' => 'brand_portfolios#add_brands', via: :post, as: :add_brand
      match 'brands' => 'brand_portfolios#brands', via: :get, as: :brands
    end
  end

  resources :brands, except: [:destroy], concerns: [:deactivatable, :filterable] do
    resources :marques, only: [:index]
  end

  resources :areas, except: [:destroy], concerns: [:deactivatable, :filterable] do
    get :select_form, on: :collection

    resources :places, only: [:new, :create, :destroy]
    member do
      get :cities
      post :assign
      delete :unassign
    end
  end

  resources :places, only: [:create, :new] do
    get :search, format: :json, on: :collection
    resources :areas, only: [:new, :create]
  end

  resources :attached_assets, only: [] do
    put :rate, on: :member
    resources :tags, only: [] do
      member do
        get :remove
        get :activate
      end
    end
  end

  resources :date_ranges, except: [:destroy], concerns: [:deactivatable, :filterable] do
    resources :date_items, path: 'dates', only: [:new, :create, :destroy]
  end

  resources :day_parts, except: [:destroy], concerns: [:deactivatable, :filterable] do
    resources :day_items, path: 'days', only: [:new, :create, :destroy]
  end

  resources :activities, only: [:show, :edit, :update], concerns: [:deactivatable] do
    member do
      get :form, to: 'activities#export_fieldable'
    end
  end

  resources :activity_types, except: [:destroy], concerns: [:deactivatable, :filterable] do
    member do
      get :form, to: 'activity_types#export_fieldable'
    end
  end

  resources :satisfaction_surveys, path: 'satisfaction', only: [:create]

  resources :dashboard, only: [] do
    match 'modules/:module' => 'dashboard#module', via: :get, on: :collection, constraints: { module: /recent_comments|recent_photos|recent_comments/ }
  end

  resources :tags, only: [:index]

  resources :custom_filters, only: [:index, :new, :create, :destroy] do
    put :default_view, on: :member, format: :json
  end

  resources :filter_settings, only: [:index, :new, :create, :update]

  match 'custom_filters_settings/:apply_to' => 'custom_filters_settings#index', via: :get, constraints: { apply_to: CustomFilter::APPLY_TO_OPTIONS.join("|") }

  resources :custom_filters_categories, only: [:index, :new, :create] do
    match 'list_filters/:apply_to' => 'custom_filters_categories#list_filters', via: :get, on: :collection, format: :json
  end

  resources :company, only: [] do
    resources :custom_filters, only: [:create, :new]
  end

  namespace :brand_ambassadors do
    resources :visits, except: [:destroy], concerns: [:deactivatable, :filterable] do
      resources :document_folders, path: 'folders', only: [:new, :create]
      resources :documents, only: [:create]
    end
    resources :document_folders, path: 'folders', only: [:new, :create, :index], concerns: [:deactivatable]
    resources :documents, only: [:edit, :create, :update, :destroy] do
      get :move, on: :member
    end
    get '/:tab', constraints: { tab: /calendar/ }, to: 'dashboard#index'
    root to: 'dashboard#index'
  end

  root to: 'dashboard#index'
end
