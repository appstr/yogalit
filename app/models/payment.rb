class Payment < ActiveRecord::Base
  # require 'active_merchant'
  has_one :yoga_session
  belongs_to :student
  belongs_to :teacher
  #
  # def self.payment_processed?(credit_card_params, amount, remote_ip)
  #   amount_in_cents = (amount * 100).round
  #   credit_card = ActiveMerchant::Billing::CreditCard.new(
  #                 :first_name         => credit_card_params[:first_name],
  #                 :last_name          => credit_card_params[:last_name],
  #                 :number             => credit_card_params[:number],
  #                 :month              => credit_card_params[:exp_month],
  #                 :year               => credit_card_params[:exp_year],
  #                 :verification_value => credit_card_params[:security_code]
  #               )
  #   if credit_card.valid?
  #     response = GATEWAY.purchase(amount_in_cents, credit_card, {ip: remote_ip})
  #     if response.success?
  #       return [true, response.params["transaction_id"]]
  #     else
  #       return [false]
  #     end
  #   else
  #     return [false]
  #   end
  # end

  def self.payment_processed?(credit_card, amount, billing_address)
    require 'paypal-sdk-rest'
    include PayPal::SDK::REST
    PayPal::SDK::REST.set_config(
      :mode => "sandbox", # "sandbox" or "live"
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
      return [true, payment.id]
    else
      return [false, payment.error]
    end
  end
end
