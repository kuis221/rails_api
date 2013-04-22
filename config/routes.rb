Brandscopic::Application.routes.draw do


  devise_for :users

  resources :activities

  scope '/admin' do
    resources :users
  end

  # resources :users, only: [] do
  #   collection do
  #     get :dashboard
  #   end
  # end


  root :to => 'users#dashboard'

end
