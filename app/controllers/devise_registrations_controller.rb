class DeviseRegistrationsController < Devise::RegistrationsController
  def create
    if params[:user][:teacher_or_student].nil?
      flash[:notice] = "Teacher or Student selection cannot be blank."
      return redirect_to request.referrer
    end
    params[:user][:email].downcase!
    build_resource(sign_up_params)
    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        respond_with resource, location: root_path
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      flash[:alert] = resource.errors.full_messages.join(', ')
      redirect_to new_user_session_path
    end
  end

  private

  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :teacher_or_student, :blacklisted)
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :teacher_or_student, :blacklisted)
  end

end
