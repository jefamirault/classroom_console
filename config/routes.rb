require 'sidekiq/web'

Rails.application.routes.draw do
  resources :tenant_variables

  resources :terms
  put 'sync_terms', to: 'terms#sync_terms'

  resources :sections do
    get 'sync'
    get 'enroll_users_in_canvas'
    get 'create_canvas_course'
  end
  get 'sync_all_grades', to: 'sections#sync_all_grades', as: 'sync_all_grades'
  get 'sync_all_sis_assignments', to: 'sections#sync_all_sis_assignments', as: 'sync_all_sis_assignments'
  get 'sync_all_canvas_sections', to: 'sections#sync_all_canvas_sections'

  resources :courses do
    get 'sync_sis_enrollments'
    get 'sync_with_canvas'
    # get 'enroll_users_in_canvas'
  end
  get 'sync_all_sis_enrollments', to: 'courses#sync_all_sis_enrollments'
  get 'sync_canvas_courses', to: 'courses#sync_canvas_courses'
  get 'full_sync', to: 'courses#full_sync'

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
  get 'refresh_sis_emails', to: 'users#refresh_sis_emails'
  get 'sync_sis_teacher_enrollments', to:'users#sync_sis_teacher_enrollments'
  get 'sync_canvas_users', to: 'users#sync_canvas_users'

  get 'public', to: 'verify#index'

  post 'subscribe', to: 'subscriptions#create', as: 'subscribe'

  root to: 'verify#index'

  get 'assignments', to: 'assignments#index', as: 'assignments'

  get 'generate_sample_data', to: 'courses#generate_sample_data', as: 'generate_sample_data'

  get 'diagnostic', to: 'diagnostic#index'
  get 'diagnostic_user', to: 'diagnostic#user'
  get 'diagnostic_course', to: 'diagnostic#course'
  get 'diagnostic_section', to: 'diagnostic#section'
  get 'diagnostic_enrollment', to: 'diagnostic#enrollment'
  get 'diagnostic_term', to: 'diagnostic#term'
  get 'diagnostic_grade', to: 'diagnostic#grade'
  get 'diagnostic_assignment', to: 'diagnostic#assignment'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :events, only: [:index, :show]

  resources :quarantines, only: [:index]
end
