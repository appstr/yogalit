class WebHooksController < ApplicationController

  if Rails.env.development?
    Braintree::Configuration.environment = :sandbox
    merchant_id = ENV["braintree_merchant_id_dev"]
    public_key = ENV["braintree_public_key_dev"]
    private_key = ENV["braintree_private_key_dev"]
  else
    Braintree::Configuration.environment = :production
    merchant_id = ENV["braintree_merchant_id_prod"]
    public_key = ENV["braintree_public_key_prod"]
    private_key = ENV["braintree_private_key_prod"]
  end
  Braintree::Configuration.merchant_id = merchant_id
  Braintree::Configuration.public_key = public_key
  Braintree::Configuration.private_key = private_key

  def sub_merchant_webhook
    notification = Braintree::WebhookNotification.parse(
      params[:bt_signature],
      params[:bt_payload]
    )
    if notification.kind == Braintree::WebhookNotification::Kind::SubMerchantAccountApproved
      if notification.merchant_account.status == "active"
        teacher = Teacher.where(user_id: notification.merchant_account.id).first
        teacher[:merchant_account_active] = true
        begin
          teacher.save!
        rescue e
          puts "RAILS_ERROR: #{e}"
        end
      end
    elsif notification.kind == Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined
      teacher_email = User.find(teacher[:user_id]).email
      # Send email with UserMailer.sub_merchant_declined_email(notification.message, teacher_email)
    end
    return render json: {success: true}
  end

  # def disbursements
  #
  # end

end
