Rails.application.routes.draw do

  # Devise handles login itself. It's first in the chain to avoid a redirect loop during
  # authentication failure.
  devise_for :users, skip: [:sessions], controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get '/users/sessions' => 'users/sessions#new', as: :new_user_session
    post '/users/sessions' => 'users/sessions#create', as: :user_session
    delete '/users/sessions' => 'users/sessions#destroy'

    get 'active'  => 'users/sessions#active'
    get 'timeout' => 'users/sessions#timeout'

    patch '/confirm' => 'users/confirmations#confirm'
  end

  namespace :users do
    resources :applications do
    end
  end

  root to: 'home#index'
end
