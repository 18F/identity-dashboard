Rails.application.routes.draw do
  devise_for :users, skip: [:sessions]

  devise_scope :user do
    get '/users/logout' => 'users/sessions#destroy', as: :destroy_user_session
    get 'active'  => 'users/sessions#active'
    get 'timeout' => 'users/sessions#timeout'
  end
  get '/auth/logindotgov/callback' => 'users/omniauth#callback'
  get 'users/none' => 'users#none'
  delete '/remove_unconfirmed_users' => 'unconfirmed_users#destroy'
  get '/env' => 'env#index'

  resources :users

  get '/teams/all' => 'teams#all'
  resources :teams do
    resources :manage_users, only: %i[new create]
  end

  get '/emails' => 'emails#index'
  get '/service_providers/all' => 'service_providers#all'
  resources :service_providers

  resources :security_events, only: :index
  get '/security_events/all' => 'security_events#all'

  post '/api/security_events' => 'api/security_events#create'
  get '/api/service_providers' => 'api/service_providers#index'
  post '/api/service_providers' => 'api/service_providers#update'

  root to: 'home#index'

  # preserve old Groups route
  match '/groups/:id', to: redirect('/teams/%{id}'), via: :get
end
