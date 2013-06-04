Brandscopic::Application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users, :controllers => { :invitations => 'invitations' }

  devise_scope :user do
    put '/users/confirmation', to: 'confirmations#update'
  end

  resources :activities


  get '/users/complete-profile', to: 'users#complete', as: :complete_profile
  put '/users/update-profile', to: 'users#update_profile', as: :update_profile

  get 'select-company/:company_id', to: 'users#select_company', as: :select_company, constraints: {company_id: /[0-9]+/}

  get "countries/states"

  resources :roles do
    member do
      get :deactivate
      get :activate
    end
    collection do
      put :set_permissions
    end
  end

  resources :users do
    resources :tasks do
      member do
        get :deactivate
        get :activate
      end
    end
    member do
      get :deactivate
      get :activate
    end
  end

  resources :teams do
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
    member do
      get :deactivate
      get :activate
      match 'members/:member_id' => 'campaigns#delete_member', via: :delete, as: :delete_member
      match 'members/new' => 'campaigns#new_member', via: :get, as: :new_member
      match 'members' => 'campaigns#add_members', via: :post, as: :add_member
    end
  end

  resources :events do
    get :autocomplete, on: :collection
    resources :tasks do
      member do
        get :deactivate
        get :activate
      end
    end

    resources :documents

    member do
      get :deactivate
      get :activate
      match 'members/:member_id' => 'events#delete_member', via: :delete, as: :delete_member
      match 'members/new' => 'events#new_member', via: :get, as: :new_member
      match 'members' => 'events#add_members', via: :post, as: :add_member
    end
  end

  resources :tasks, only: [:new, :create, :edit, :update] do
    collection do
      get :mine, to: :index, :defaults => {:scope => "user"}, :constraints => { :scope => 'user' }
      get :my_teams, to: :index, :defaults => {:scope => "teams"}, :constraints => { :scope => 'teams' }
    end
    member do
      get :deactivate
      get :activate
    end
    resources :comments
  end

  resources :brand_portfolios do
    resources :brands, only: [:index, :new, :create]
    member do
      get :deactivate
      get :activate
      match 'brands/:brand_id' => 'brand_portfolios#delete_brand', via: :delete, as: :delete_brand
      match 'brands/select' => 'brand_portfolios#select_brands', via: :get, as: :select_brands
      match 'brands/add' => 'brand_portfolios#add_brands', via: :post, as: :add_brand
    end
  end

  resources :brands, only: [:index]

  root :to => 'dashboard#index'
end
