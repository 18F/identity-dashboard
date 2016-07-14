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

  namespace :users do
    resources :service_providers do
    end
  end

  root to: 'home#index'
end
