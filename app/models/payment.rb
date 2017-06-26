class Payment < ActiveRecord::Base
  # require 'active_merchant'
  has_one :yoga_session
  belongs_to :student
  belongs_to :teacher

  require 'securerandom'

  def self.refund_successful?(transaction_id)
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
    result = Braintree::Transaction.refund(transaction_id)
    if result.success?
      return true
    else
      return false
    end
  end

  def self.teacher_payouts
    payout_hash = get_teacher_payout_hash
    return true if payout_hash == true
    create_teacher_payouts(payout_hash)
  end

  def self.get_teacher_payout_hash
    payout_hash = {}
    booked_times = TeacherBookedTime.where("session_date <= ?", Date.today - 3)
    # booked_times = TeacherBookedTime.all
    return true if booked_times.blank?
    booked_times.each do |bt|
      yoga_session = YogaSession.where(teacher_booked_time_id: bt).first
      if yoga_session[:video_under_review] == false && yoga_session[:teacher_payout_made] == false && yoga_session[:student_refund_given] == false
        payment = Payment.find(yoga_session[:payment_id])
        teacher = Teacher.find(yoga_session[:teacher_id])
        payout_hash["payment_#{yoga_session[:id]}"] = {}
        payout_hash["payment_#{yoga_session[:id]}"]["amount"] = payment[:teacher_payout_amount]
        payout_hash["payment_#{yoga_session[:id]}"]["payment_id"] = payment[:id]
        payout_hash["payment_#{yoga_session[:id]}"]["yoga_session_id"] = yoga_session[:id]
        payout_hash["payment_#{yoga_session[:id]}"]["payout_email"] = teacher[:paypal_email]
      end
    end
    return true if payout_hash.blank?
    payout_hash
  end

  def self.create_teacher_payouts(payout_hash)
    include PayPal::SDK::REST
    include PayPal::SDK::Core::Logging
    PayPal::SDK::REST.set_config(
    :mode => "sandbox", # "sandbox" or "live"
    :client_id => ENV["paypal_client_id"],
    :client_secret => ENV["paypal_client_secret"])
    payout_hash.each do |k, v|
      payout = Payout.new({
                           :sender_batch_header => {
                               :sender_batch_id => SecureRandom.hex(8),
                               :email_subject => 'Yogalit Payment!'
                           },
                           :items => [
                                  {
                                      :recipient_type => 'EMAIL',
                                      :amount => {
                                          :value => "#{v['amount']}",
                                          :currency => 'USD'
                                      },
                                      :note => 'Thanks for supporting Yogalit!',
                                      :sender_item_id => "#{v['payment_id']}",
                                      :receiver => "#{v['payout_email']}"
                                  }
                           ]
                       })
       begin
         payout_batch = payout.create
         yoga_session = YogaSession.find(v["yoga_session_id"])
         yoga_session[:teacher_payout_made] = true
         yoga_session.save!
       rescue ResourceNotFound => err
         puts err
       end
    end
  end

end
