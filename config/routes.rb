Rails.application.routes.draw do
  devise_for :users, skip: [:sessions]

  devise_scope :user do
    get '/users/logout' => 'users/sessions#destroy', as: :destroy_user_session
    get 'active'  => 'users/sessions#active'
    get 'timeout' => 'users/sessions#timeout'
  end
  get '/auth/logindotgov/callback' => 'users/omniauth#callback'
  get 'users/none' => 'users#none'

  resources :users
  resources :groups

  get '/emails' => 'emails#index'
  get '/service_providers/all' => 'service_providers#all'
  get '/api/service_providers' => 'api/service_providers#index'
  post '/api/service_providers' => 'api/service_providers#update'
  resources :service_providers

  root to: 'home#index'
end
