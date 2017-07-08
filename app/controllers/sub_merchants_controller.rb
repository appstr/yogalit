class SubMerchantsController < ApplicationController
  before_action :authenticate_user!

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

  def new
    @teacher = Teacher.where(user_id: current_user).first
  end

  def create
    teacher = Teacher.where(user_id: current_user).first
    merchant_account_params = {
      individual: {
        first_name: params[:first_name],
        last_name: params[:last_name],
        email: params[:email],
        phone: params[:phone],
        date_of_birth: "#{params[:dob_year]}-#{params[:dob_month]}-#{params[:dob_day]}",
        ssn: params[:ssn],
        address: {
          street_address: params[:street_address],
          locality: params[:city],
          region: params[:state],
          postal_code: params[:postal]
        }
      }
    }
    if teacher[:registered_business]
      merchant_account_params[:business] = {
        legal_name: params[:legal_name],
        tax_id: params[:tax_id]
      }
    end
    if teacher[:payout_type] == "bank"
      merchant_account_params[:funding] = {
        destination: teacher[:payout_type],
        account_number: params[:account_number],
        routing_number: params[:routing_number]
      }
    elsif teacher[:payout_type] == "mobile_phone"
      merchant_account_params[:funding] = {
        destination: teacher[:payout_type],
        mobile_phone: params[:mobile_phone]
      }
    else
      merchant_account_params[:funding] = {
        destination: teacher[:payout_type],
        email: params[:email]
      }
    end
    merchant_account_params[:master_merchant_account_id] = "yogalit"
    merchant_account_params[:tos_accepted] = true
    merchant_account_params[:id] = current_user[:id].to_s
    result = Braintree::MerchantAccount.create(merchant_account_params)
    if result.success?
      teacher[:merchant_account_requested] = true
      teacher[:merchant_account_id] = current_user[:id]
      teacher[:merchant_account_active] = false
      begin
        teacher.save!
      rescue e
        puts e
      end
      return google_authorize_teacher
    else
      return redirect_to request.referrer
    end
  end
end
