Brandscopic::Application.routes.draw do



  devise_for :users

  resources :activities



  get '/users/complete-profile', to: 'users#complete', as: :complete_profile
  put '/users/update-profile', to: 'users#update_profile', as: :update_profile

  get "countries/states"

  scope '/admin' do
    resources :user_groups do
      collection do
        put :set_permissions
      end
    end

    resources :users do
      member do
        get :deactivate
      end
    end

    resources :teams do
      member do
        get :deactivate
        get :users
      end
    end
  end

  root :to => 'users#dashboard'

end
