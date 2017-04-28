class Payment < ActiveRecord::Base
  require 'active_merchant'
  has_one :yoga_session
  belongs_to :student
  belongs_to :teacher

  def self.payment_processed?(credit_card_params, amount, remote_ip)
    amount_in_cents = (amount * 100).round
    credit_card = ActiveMerchant::Billing::CreditCard.new(
                  :first_name         => credit_card_params[:first_name],
                  :last_name          => credit_card_params[:last_name],
                  :number             => credit_card_params[:number],
                  :month              => credit_card_params[:exp_month],
                  :year               => credit_card_params[:exp_year],
                  :verification_value => credit_card_params[:security_code]
                )
    if credit_card.valid?
      response = GATEWAY.purchase(amount_in_cents, credit_card, {ip: remote_ip})
      if response.success?
        return [true, response.params["transaction_id"]]
      else
        return [false]
      end
    else
      return [false]
    end
  end
end
