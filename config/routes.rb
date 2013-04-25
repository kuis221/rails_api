Brandscopic::Application.routes.draw do


  devise_for :users

  resources :activities

  scope '/admin' do
    resources :user_groups

    resources :users do
      member do
        get :deactivate
      end
    end
  end


  root :to => 'users#dashboard'

end
