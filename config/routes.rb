Rails.application.routes.draw do
  devise_for :users, skip: [:sessions]

  devise_scope :user do
    get '/users/sessions' => 'users/sessions#new', as: :new_user_session
    post '/users/sessions' => 'users/sessions#create', as: :user_session
    get '/users/result' => 'users/sessions#result'
    get '/users/logout' => 'users/sessions#destroy', as: :destroy_user_session
    get 'active'  => 'users/sessions#active'
    get 'timeout' => 'users/sessions#timeout'
  end

  get 'users/none' => 'users#none'
  resources :users

  resources :groups, except: [:show]

  get '/emails' => 'emails#index'
  get '/service_providers/all' => 'service_providers#all'
  get '/api/service_providers' => 'api/service_providers#index'
  post '/api/service_providers' => 'api/service_providers#update'
  resources :service_providers

  root to: 'home#index'
end
