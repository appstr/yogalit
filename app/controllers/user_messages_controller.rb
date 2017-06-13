class UserMessagesController < ApplicationController
  def new
    @user_message = UserMessage.new
    if user_signed_in?
      if current_user[:teacher_or_student] == "teacher"
        @teacher = Teacher.where(user_id: current_user).first
      elsif current_user[:teacher_or_student] == "student"
        @student = Student.where(user_id: current_user).first
      end
    end
  end

  def create
    new_message = UserMessage.new(new_message_params)
    new_message[:user_id] = current_user[:id] if user_signed_in?
    if new_message.save!
      UserMailer.message_to_yogalit(new_message).deliver_now
      flash[:notice] = "Your message was sent successfully!"
    else
      flash[:notice] = "Your message was unable to be sent, please try again."
      return redirect_to request.referrer
    end
    return redirect_to root_path
  end

  private

  def new_message_params
    params.require(:user_message).permit(:user_id, :email, :subject, :message)
  end
end
