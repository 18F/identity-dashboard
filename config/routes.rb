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

  resources :service_providers
  resources :groups, except: [:show]
  resources :users, only: %i(index edit update)

  get '/api/service_providers' => 'api/service_providers#index'
  post '/api/service_providers' => 'api/service_providers#update'

  root to: 'home#index'
end
