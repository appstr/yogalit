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
        teacher = Teacher.where(merchant_account_id: notification.merchant_account.id).first
        teacher[:merchant_account_active] = true
        teacher[:merchant_account_denied] = false
        begin
          teacher.save!
        rescue e
          puts "RAILS_ERROR: #{e}"
          # Mail "failed to save approved merchant web-hook"
        end
      end
    elsif notification.kind == Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined
      teacher = Teacher.where(merchant_account_id: notification.merchant_account.id).first
      teacher[:merchant_account_denied] = true
      begin
        teacher.save
      rescue e
        puts "RAILS_ERROR: #{e}"
      end
      # Send email with UserMailer.sub_merchant_declined_email(notification.message, teacher_email)
      # Add link to allow Teacher to re-submit their application to Braintree on the dashboard in the "general" tab.
    elsif notification.kind == Braintree::WebhookNotification::Kind::Check
      puts "BRAINTREE WEBHOOK SUCCESSFUL!!!"
    end
    return render json: {success: true}
  end

end
