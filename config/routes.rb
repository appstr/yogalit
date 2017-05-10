Rails.application.routes.draw do
  # TODO Need to restrict resources to specific actions on those who do not use full CRUD.
  devise_for :users, :controllers => { registrations: "devise_registrations" }
  resources :users, only: [:index]
  resources :students
  resources :teachers
  resources :teacher_monday_time_frames
  resources :teacher_tuesday_time_frames
  resources :teacher_wednesday_time_frames
  resources :teacher_thursday_time_frames
  resources :teacher_friday_time_frames
  resources :teacher_saturday_time_frames
  resources :teacher_sunday_time_frames
  resources :yoga_types
  resources :teacher_images
  resources :teacher_videos
  resources :teacher_holidays
  resources :payments
  resources :yogalit_admins
  resources :teacher_price_ranges
  root to: 'users#index'

  # YogaTeacherSearches
  get '/search_for_teachers', to: 'yoga_teacher_searches#search_for_teachers', as: :search_for_teachers

  # YogaSessions
  get '/live_yoga_session', to: 'yoga_sessions#live_yoga_session', as: :live_yoga_session
  get '/report_a_yoga_session_problem', to: 'yoga_sessions#report_a_yoga_session_problem', as: :report_a_yoga_session_problem
  post '/submit_yoga_session_problem', to: 'yoga_sessions#submit_yoga_session_problem', as: :submit_yoga_session_problem
  post 'refund_yoga_session', to: 'yoga_sessions#refund_yoga_session', as: :refund_yoga_session
  post 'general_refund_denial', to: 'yoga_sessions#general_refund_denial', as: :general_refund_denial
  post 'custom_refund_denial', to: 'yoga_sessions#custom_refund_denial', as: :custom_refund_denial

  # Teachers
  get '/teacher_profile', to: 'teachers#teacher_profile', as: :teacher_profile
  # get '/google_authorize_teacher', to: 'teachers#google_authorize_teacher', as: :google_authorize_teacher
  get '/new_teacher_interview', to: 'teachers#new_teacher_interview', as: :new_teacher_interview
  post 'confirm_teacher_interview', to: 'teachers#confirm_teacher_interview', as: :confirm_teacher_interview

  # Students
  delete '/destroy_favorite_teacher', to: 'students#destroy_favorite_teacher', as: :destroy_favorite_teacher
  post '/add_favorite_teacher', to: 'students#add_favorite_teacher', as: :add_favorite_teacher

  # YogalitAdmins
  get '/reported_non_refund_requested_yoga_sessions', to: 'yogalit_admins#reported_non_refund_requested_yoga_sessions', as: :admins_reported_non_refund_requested_yoga_sessions
  get '/reported_refund_requested_yoga_sessions', to: 'yogalit_admins#reported_refund_requested_yoga_sessions', as: :admins_reported_refund_reuqested_yoga_sessions
end
