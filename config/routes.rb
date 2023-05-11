Rails.application.routes.draw do
  devise_for :users, skip: [:sessions]

  devise_scope :user do
    get '/users/logout' => 'users/sessions#destroy', as: :destroy_user_session
  end
  get '/auth/logindotgov/callback' => 'users/omniauth#callback'
  get 'users/none' => 'users#none'
  delete '/remove_unconfirmed_users' => 'unconfirmed_users#destroy'
  get '/env' => 'env#index'

  resources :users

  get '/teams/all' => 'teams#all'
  resources :teams

  scope module: 'teams' do
    resources :teams do
      get '/users/:id/remove_confirm' => 'users#remove_confirm'
      resources :users
    end
  end

  get '/tools' => 'tools#new'
  post '/tools' => 'tools#index'

  get '/emails' => 'emails#index'
  get '/service_providers/all' => 'service_providers#all'
  resources :service_providers

  get '/security_events/all' => 'security_events#all'
  post '/security_events/search' => 'security_events#search'
  resources :security_events, only: %i[index show]

  post '/api/security_events' => 'api/security_events#create'
  get '/api/service_providers' => 'api/service_providers#index'
  get '/api/service_providers/:id' => 'api/service_providers#show'
  post '/api/service_providers' => 'api/service_providers#update'

  root to: 'home#index'

  # preserve old Groups route
  match '/groups/:id', to: redirect('/teams/%{id}'), via: :get
end
