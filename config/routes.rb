Rails.application.routes.draw do
  root to: 'users#index'
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
  resources :user_messages
  resources :teacher_ratings

  # YogaTeacherSearches
  get '/search_for_teachers', to: 'yoga_teacher_searches#search_for_teachers', as: :search_for_teachers

  # YogaSessions
  get '/live_yoga_session', to: 'yoga_sessions#live_yoga_session', as: :live_yoga_session
  get '/report_a_yoga_session_problem', to: 'yoga_sessions#report_a_yoga_session_problem', as: :report_a_yoga_session_problem
  post '/submit_yoga_session_problem', to: 'yoga_sessions#submit_yoga_session_problem', as: :submit_yoga_session_problem

  # Teachers
  get '/teacher_profile', to: 'teachers#teacher_profile', as: :teacher_profile
  get '/new_teacher_interview', to: 'teachers#new_teacher_interview', as: :new_teacher_interview
  post '/confirm_teacher_interview', to: 'teachers#confirm_teacher_interview', as: :confirm_teacher_interview
  post '/toggle_vacation_mode', to: 'teachers#toggle_vacation_mode', as: :toggle_vacation_mode
  post '/emergency_cancel', to: 'teachers#emergency_cancel', as: :emergency_cancel

  # Students
  delete '/destroy_favorite_teacher', to: 'students#destroy_favorite_teacher', as: :destroy_favorite_teacher
  post '/add_favorite_teacher', to: 'students#add_favorite_teacher', as: :add_favorite_teacher
  get '/switch_time_frame', to: 'students#switch_time_frame', as: :switch_time_frame

  # YogalitAdmins
  get '/reported_non_refund_requested_yoga_sessions', to: 'yogalit_admins#reported_non_refund_requested_yoga_sessions', as: :admins_reported_non_refund_requested_yoga_sessions
  get '/reported_refund_requested_yoga_sessions', to: 'yogalit_admins#reported_refund_requested_yoga_sessions', as: :admins_reported_refund_reuqested_yoga_sessions
  get '/teacher_interviews', to: 'yogalit_admins#teacher_interviews', as: :admins_teacher_interviews
  post '/verify_teacher', to: 'yogalit_admins#verify_teacher', as: :admins_verify_teacher
  post '/deny_teacher', to: 'yogalit_admins#deny_teacher', as: :admins_deny_teacher
  post '/block_student', to: 'yogalit_admins#block_student', as: :admins_block_student
  post '/dismiss_report_without_action', to: 'yogalit_admins#dismiss_report_without_action', as: :admins_dismiss_report_without_action
  post '/teacher_no_show', to: 'yogalit_admins#teacher_no_show', as: :teacher_no_show
  post '/teacher_payouts', to: 'yogalit_admins#teacher_payouts', as: :admins_teacher_payouts

  # Payments
  post '/student_refund_request', to: 'payments#student_refund_request', as: :student_refund_request
  post '/refund_yoga_session', to: 'payments#refund_yoga_session', as: :refund_yoga_session
  post '/general_refund_denial', to: 'payments#general_refund_denial', as: :general_refund_denial
  post '/custom_refund_denial', to: 'payments#custom_refund_denial', as: :custom_refund_denial

  # Policies
  get '/privacy_policy', to: 'policies#privacy_policy', as: :privacy_policy
  get '/terms_and_conditions', to: 'policies#terms_and_conditions', as: :terms_and_conditions

end
