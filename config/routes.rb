Rails.application.routes.draw do
  resources :terms
  resources :sections
  resources :courses
  devise_scope :user do
    get "/sign_in" => "devise/sessions#new" # custom path to login/sign_in
    # get "/sign_up" => "devise/registrations#new", as: "new_user_registration" # custom path to sign_up/registration
  end
  # devise_for :users, :skip => [:registrations]
  # as :user do
  #   get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
  #   put 'users' => 'devise/registrations#update', :as => 'user_registration'
  # end

  devise_for :users

  resources :users

  get 'verify/index'

  post 'subscribe', to: 'subscriptions#create', as: 'subscribe'

  root to: 'verify#index'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
