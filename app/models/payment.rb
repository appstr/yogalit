class Payment < ActiveRecord::Base
  # require 'active_merchant'
  has_one :yoga_session
  belongs_to :student
  belongs_to :teacher

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

  def self.refund_successful?(transaction_id)
    result = Braintree::Transaction.refund(transaction_id)
    if result.success?
      return true
    else
      return false
    end
  end

  def self.teacher_payouts
    booked_times = TeacherBookedTime.where("session_date == ?", Date.today - 3)
    return true if booked_times.blank?
    booked_times.each do |bt|
      yoga_session = YogaSession.where(teacher_booked_time_id: bt).first
      if yoga_session[:video_under_review] == false && yoga_session[:teacher_payout_made] == false && yoga_session[:student_refund_given] == false
        payment = Payment.find(yoga_session[:payment_id])
        result = Braintree::Transaction.release_from_escrow(payment[:transaction_id])
        if result.success?
           yoga_session[:teacher_payout_made] = true
           save_yoga_session(yoga_session)
        end
      end
    end
    return true
  end

  def save_yoga_session(yoga_session)
    begin
      yoga_session.save!
    rescue e
      puts "Payout to Yoga-Session-ID: #{yoga_session[:id]} FAILED TO SAVE!!!"
      UserMailer.send_payout_failure_email(yoga_session[:id]).deliver_now
    end
  end

end
