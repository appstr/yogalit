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
  root to: 'users#index'

  get '/search_for_teachers', to: 'yoga_teacher_searches#search_for_teachers', as: :search_for_teachers
end
