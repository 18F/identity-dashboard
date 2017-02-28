Rails.application.routes.draw do
  # Devise handles login itself. It's first in the chain to avoid a redirect loop during
  # authentication failure.
  devise_for :users, skip: [:sessions], controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get '/users/sessions' => 'users/sessions#new', as: :new_user_session
    post '/users/sessions' => 'users/sessions#create', as: :user_session
    post '/users/auth/saml/logout' => 'users/omniauth_callbacks#logout'
    get '/users/logout' => 'users/sessions#destroy', as: :destroy_user_session
    get 'active'  => 'users/sessions#active'
    get 'timeout' => 'users/sessions#timeout'
  end

  get '/users/service_providers' => 'users/service_providers#index', as: 'users_service_providers'
  post '/users/service_providers' => 'users/service_providers#create'
  get '/users/service_providers/new' => 'users/service_providers#new',
      as: 'new_users_service_provider'
  get '/users/service_providers/:id/edit' => 'users/service_providers#edit',
      as: 'edit_users_service_provider'
  get '/users/service_providers/:id' => 'users/service_providers#show', as: 'users_service_provider'
  patch '/users/service_providers/:id' => 'users/service_providers#update'
  put '/users/service_providers/:id' => 'users/service_providers#update'
  delete '/users/service_providers/:id' => 'users/service_providers#destroy'

  get '/api/service_providers' => 'api/service_providers#index'
  post '/api/service_providers' => 'api/service_providers#update'

  resources :organizations
  patch '/organizations/:id/new_user' => 'organizations#new_user', as: 'new_organization_user'
  patch '/organizations/:id/new_service_provider' => 'organizations#new_service_provider', as: 'new_organization_service_provider'
  delete '/organizations/:id/remove_user/:user_id' => 'organizations#remove_user', as: 'remove_organization_user'
  delete '/organizations/:id/remove_service_provider/:service_provider_id' => 'organizations#remove_service_provider', as: 'remove_organization_service_provider'

  root to: 'home#index'
end
