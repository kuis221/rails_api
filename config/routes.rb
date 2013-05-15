Brandscopic::Application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users
  ActiveAdmin.routes(self)

  resources :activities

  get '/users/complete-profile', to: 'users#complete', as: :complete_profile
  put '/users/update-profile', to: 'users#update_profile', as: :update_profile

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
    member do
      get :deactivate
      get :activate
    end
  end

  resources :teams do
    member do
      get :deactivate
      get :activate
      get :users
    end
  end

  resources :campaigns do
    member do
      get :deactivate
      get :activate
    end
  end

  resources :events do
    resources :tasks do
      collection do
        get :progress_bar
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

  resources :tasks, only: [] do
    resources :comments
  end

  root :to => 'dashboard#index'
end
