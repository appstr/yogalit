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
      request.params[:bt_signature],
      request.params[:bt_payload]
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
          # TODO: Mail "failed to save approved merchant web-hook" to Admin.
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
      # TODO: Send email with UserMailer.sub_merchant_declined_email(notification.message, teacher_email)
    elsif notification.kind == Braintree::WebhookNotification::Kind::Check
      puts "BRAINTREE WEBHOOK SUCCESSFUL!!!"
    end
    return render json: {success: true}
  end

  def disbursment_webhook
    notification = Braintree::WebhookNotification.parse(
      request.params[:bt_signature],
      request.params[:bt_payload]
    )
    new_transactions = false
    if notification.kind == Braintree::WebhookNotification::Kind::Disbursement
      teacher = Teacher.where(merchant_account_id: notification.disbursement.merchant_account.id).first
      disbursem = Disbursement.where(braintree_disbursement_id: notification.disbursement.id).first
      if disbursem.nil?
        disbursem = Disbursement.new
        new_transactions = true
      end
      disbursem[:teacher_id] = teacher[:id]
      disbursem[:braintree_disbursement_id] = notification.disbursement.id
      disbursem[:amount] = notification.disbursement.amount
      disbursem[:disbursement_date] = notification.disbursement.disbursement_date
      disbursem[:successful_disbursement] = notification.disbursement.success?
    elsif notification.kind == Braintree::WebhookNotification::Kind::DisbursementException
      teacher = Teacher.where(merchant_account_id: notification.disbursement.merchant_account.id).first
      disbursem = Disbursement.where(braintree_disbursement_id: notification.disbursement.id).first
      if disbursem.nil?
        disbursem = Disbursement.new
        new_transactions = true
      end
      disbursem[:teacher_id] = teacher[:id]
      disbursem[:braintree_disbursement_id] = notification.disbursement.id
      disbursem[:amount] = notification.disbursement.amount
      disbursem[:disbursement_date] = notification.disbursement.disbursement_date
      disbursem[:successful_disbursement] = notification.disbursement.success?
      disbursem[:exception_message] = notification.disbursement.exception_message
      disbursem[:follow_up_action] = notification.disbursement.follow_up_action
    end
    begin
      disbursem.save
    rescue e
      puts "RAILS_ERROR: #{e}. DisbursementID: #{notification.disbursement.id}, TeacherID: #{teacher[:id]}"
    end
    if new_transactions
      notification.disbursement.transaction_ids.each do |ti|
        t = Transaction.new
        t[:disbursement_id] = disbursem[:id]
        t[:trans_id] = ti
        begin
          t.save
        rescue e
          puts "RAILS_ERROR: #{e}. TransactionID: #{ti}, TeacherID: #{teacher[:id]}, DisbursementID: #{notification.disbursement.id}"
        end
      end
    end
  end

  def dispute_webhook
    notification = Braintree::WebhookNotification.parse(
      request.params[:bt_signature],
      request.params[:bt_payload]
    )
    if notification.kind == Braintree::WebhookNotification::Kind::DisputeOpened || notification.kind == Braintree::WebhookNotification::Kind::DisputeWon || notification.kind == Braintree::WebhookNotification::Kind::DisputeLost
      d = Disupute.where(braintree_dispute_id: notification.dispute.id).first
      if d.nil?
        d = Dispute.new
        d[:braintree_dispute_id] = notification.dispute.id
        d[:amount_requested] = notification.dispute.amount
        d[:received_date] = notification.dispute.received_date
        d[:reply_date] = notification.dispute.reply_date
        d[:date_opened] = notification.dispute.date_opened
        if notification.dispute.reason == :cancelled_recurring_transaction
          d[:reason] = "cancelled_recurring_transaction"
        elsif notification.dispute.reason == :credit_not_processed
          d[:reason] = "credit_not_processed"
        elsif notification.dispute.reason == :duplicate
          d[:reason] = "duplicate"
        elsif notification.dispute.reason == :fraud
          d[:reason] = "fraud"
        elsif notification.dispute.reason == :general
          d[:reason] = "general"
        elsif notification.dispute.reason == :invalid_account
          d[:reason] = "invalid_account"
        elsif notification.dispute.reason == :not_recognized
          d[:reason] = "not_recognized"
        elsif notification.dispute.reason == :product_not_received
          d[:reason] = "product_not_received"
        elsif notification.dispute.reason == :product_unsatisfactory
          d[:reason] = "product_unsatisfactory"
        elsif notification.dispute.reason == :transaction_amount_differs
          d[:reason] = "transaction_amount_differs"
        end
        d[:trans_id] = notification.dispute.transaction_details.id
        d[:disbursement_id] = Transaction.find(d[:trans_id]).disbursement_id
        d[:trans_amount] = notification.dispute.transaction_details.amount
      end
      if notification.kind == Braintree::WebhookNotification::Kind::DisputeWon
        d[:date_won] = notification.dispute.date_won
      end
      if notification.dispute.status == :open
        d[:status] = "open"
      elsif notification.dispute.status == :won
        d[:status] = "won"
      elsif notification.dispute.status == :lost
        d[:status] = "lost"
      end
      begin
        d.save
      rescue e
        puts "RAILS_ERROR: #{e}"
      end
    end
    # TODO: Send email to Admin notifying us when a dispute is made or updated.
  end

end
