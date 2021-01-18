Rails.application.routes.draw do
  resources :tenant_variables
  resources :terms
  put 'detect_terms', to: 'terms#detect'
  resources :sections do
    get 'sync'
  end
  get 'sync_all_grades', to: 'sections#sync_all_grades', as: 'sync_all_grades'
  get 'sync_all_sis_assignments', to: 'sections#sync_all_sis_assignments', as: 'sync_all_sis_assignments'

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

  get 'public', to: 'verify#index'

  post 'subscribe', to: 'subscriptions#create', as: 'subscribe'

  root to: 'verify#index'

  get 'assignments', to: 'assignments#index', as: 'assignments'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
