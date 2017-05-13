class UserMessagesController < ApplicationController
  def new
    @user_message = UserMessage.new
  end

  def create
    new_message = UserMessage.new(new_message_params)
    new_message[:user_id] = current_user[:id] if user_signed_in?
    if new_message.save!
      # TODO send email to Yogalit admin with the :email, :subject and :message attached.
      flash[:notice] = "Your message was sent successfully!"
      puts "EMAIL SENT!"
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
