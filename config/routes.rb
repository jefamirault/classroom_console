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


  resources :sync_profiles do |p|
    get 'generate_subscriptions'
    get 'sync_now'
  end

  resources 'subscriptions'
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

  get 'admin', to: 'admin#index'
  patch 'admin_setting', to: 'admin#update'
  get 'test_canvas_api', to: 'admin#test_canvas_api'
  get 'test_on_api', to: 'admin#test_on_api'

  get 'dashboard', to: 'dashboard#index'

  get 'grades', to: 'grades#index'

  scope 'on_api' do
    get '', to: 'on_api#index', as: 'on_api'
    %w[school_years terms courses sections teacher_sections assignments assignment_grades departments roles users].each do |record|
      get "get_#{record}", to: "on_api#get_#{record}", as: "on_api_get_#{record}"
    end
  end

  scope 'canvas_api' do
    get '', to: 'canvas_api#index', as: 'canvas_api'
    get 'get_roles', to: 'canvas_api#get_roles', as: 'canvas_api_get_roles'
  end

end
