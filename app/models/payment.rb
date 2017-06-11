class Payment < ActiveRecord::Base
  # require 'active_merchant'
  has_one :yoga_session
  belongs_to :student
  belongs_to :teacher

  require 'paypal-sdk-rest'
  require 'securerandom'

  def self.payment_processed?(credit_card, amount, billing_address)
    require 'paypal-sdk-rest'
    include PayPal::SDK::REST
    mode = Rails.environment.development? ? "sandbox" : "live"
    PayPal::SDK::REST.set_config(
      :mode => mode, # "sandbox" or "live"
      :client_id => ENV["paypal_client_id"],
      :client_secret => ENV["paypal_client_secret"])

    # Build Payment object
    payment = Payment.new({
      :intent => "sale",
      :payer => {
        :payment_method => "credit_card",
        :funding_instruments => [{
          :credit_card => {
            :type => credit_card[:card_type],
            :number => credit_card[:card_number],
            :expire_month => credit_card[:exp_month],
            :expire_year => credit_card[:exp_year],
            :cvv2 => credit_card[:security_code],
            :first_name => credit_card[:first_name],
            :last_name => credit_card[:last_name],
            :billing_address => {
              :line1 => billing_address[:street_address],
              :city => billing_address[:city],
              :state => billing_address[:state],
              :postal_code => billing_address[:postal],
              :country_code => "US" }}}]},
      :transactions => [{
        :item_list => {
          :items => [{
            :name => "Yoga-Session",
            :sku => "Yoga-Session",
            :price => amount,
            :currency => "USD",
            :quantity => 1 }]},
        :amount => {
          :total => amount,
          :currency => "USD" },
        :description => "Yogalit Yoga-Session" }]})

# Create Payment and return the status(true or false)
    if payment.create
      return [true, payment.transactions[0].related_resources[0].sale.id]
    else
      return [false, payment.error]
    end
  end

  def self.refund_successful?(transaction_id)
    require 'paypal-sdk-rest'
    include PayPal::SDK::REST
    include PayPal::SDK::Core::Logging
    PayPal::SDK::REST.set_config(
      :mode => "sandbox", # "sandbox" or "live"
      :client_id => ENV["paypal_client_id"],
      :client_secret => ENV["paypal_client_secret"])
    sale = Sale.find(transaction_id)
    refund = sale.refund_request({})
    if refund.success?
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
