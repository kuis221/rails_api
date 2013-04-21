Brandscopic::Application.routes.draw do


  devise_for :users

  resources :activities

  scope '/admin' do
    resources :users
  end


  root :to => 'activities#index'

end
