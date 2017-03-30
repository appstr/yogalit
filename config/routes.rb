Rails.application.routes.draw do
  # TODO Need to restrict resources to specific actions on those who do not use full CRUD.
  devise_for :users, :controllers => { registrations: "devise_registrations" }
  resources :users, only: [:index]
  resources :teachers
  resources :teacher_monday_time_frames
  resources :teacher_tuesday_time_frames
  resources :teacher_wednesday_time_frames
  resources :teacher_thursday_time_frames
  resources :teacher_friday_time_frames
  resources :teacher_saturday_time_frames
  resources :teacher_sunday_time_frames
  resources :yoga_types
  root to: 'users#index'
end
