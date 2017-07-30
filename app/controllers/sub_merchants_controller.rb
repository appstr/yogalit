class SubMerchantsController < ApplicationController
  before_action :authenticate_user!
  require 'securerandom'

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
    if @teacher[:merchant_account_requested]
      return redirect_to teachers_path
    end
  end

  def create
    teacher = Teacher.where(user_id: current_user).first
    subm = SubMerchant.where(teacher_id: teacher).first
    if !subm.nil?
      flash[:notice] = "You already have a Sub-Merchant account. Try 'Updating' instead."
      return redirect_to teachers_path
    end
    # TODO: Build session params for form
    if teacher[:merchant_account_requested]
      return redirect_to teachers_path
    end
    unique_merchant_id = SecureRandom.hex(16)
    merchant_account_params = {
      individual: {
        first_name: params[:sub_merchant][:first_name],
        last_name: params[:sub_merchant][:last_name],
        email: params[:sub_merchant][:email],
        phone: params[:sub_merchant][:phone],
        date_of_birth: "#{params[:sub_merchant][:dob_year]}-#{params[:sub_merchant][:dob_month]}-#{params[:sub_merchant][:dob_day]}",
        ssn: params[:sub_merchant][:ssn],
        address: {
          street_address: params[:sub_merchant][:street_address],
          locality: params[:sub_merchant][:locality],
          region: params[:sub_merchant][:region],
          postal_code: params[:sub_merchant][:postal_code]
        }
      }
    }
    if params[:sub_merchant][:registered_business]
      merchant_account_params[:business] = {
        legal_name: params[:sub_merchant][:legal_name],
        tax_id: params[:sub_merchant][:tax_id]
      }
    end
    if params[:sub_merchant][:payout_type] == "bank"
      merchant_account_params[:funding] = {
        destination: params[:sub_merchant][:payout_type],
        account_number: params[:sub_merchant][:account_number],
        routing_number: params[:sub_merchant][:routing_number]
      }
    elsif params[:sub_merchant][:payout_type] == "mobile_phone"
      merchant_account_params[:funding] = {
        destination: params[:sub_merchant][:payout_type],
        mobile_phone: params[:sub_merchant][:venmo_mobile_phone]
      }
    else
      merchant_account_params[:funding] = {
        destination: params[:sub_merchant][:payout_type],
        email: params[:sub_merchant][:venmo_email]
      }
    end
    if Rails.env.production?
      merchant_account_params[:master_merchant_account_id] = "Yogalitcom_marketplace"
    else
      merchant_account_params[:master_merchant_account_id] = "yogalit"
    end
    merchant_account_params[:tos_accepted] = true
    merchant_account_params[:id] = unique_merchant_id
    result = Braintree::MerchantAccount.create(merchant_account_params)
    if result.success?
      # TODO: Destroy session params
      teacher[:merchant_account_requested] = true
      teacher[:merchant_account_id] = unique_merchant_id
      teacher[:merchant_account_active] = false
      save_sub_merchant(merchant_account_params[:individual][:date_of_birth], teacher[:id])
      begin
        teacher.save!
      rescue e
        puts "RAILS_ERROR: #{e}"
      end
      flash[:notice] = "Braintree submission successful!"
      return redirect_to teachers_path
    else
      flash[:notice] = "Something went wrong. Please try again."
      return redirect_to request.referrer
    end
  end

  def edit
    @teacher = Teacher.find(params[:id])
    @subm = SubMerchant.where(teacher_id: @teacher).first
    split_dob(@subm.date_of_birth.split("-"))
  end

  def update
    @teacher = Teacher.find(params[:id])
    @subm = SubMerchant.where(teacher_id: @teacher).first
    attr_hash = {
      individual: {
        first_name: params[:sub_merchant][:first_name],
        last_name: params[:sub_merchant][:last_name],
        email: params[:sub_merchant][:email],
        phone: params[:sub_merchant][:phone],
        date_of_birth: "#{params[:dob_year]}-#{params[:dob_month]}-#{params[:dob_day]}",
        ssn: params[:sub_merchant][:ssn],
        address: {
          street_address: params[:sub_merchant][:street_address],
          locality: params[:sub_merchant][:locality],
          region: params[:sub_merchant][:region],
          postal_code: params[:sub_merchant][:postal_code]
        }
      }
    }
    if params[:sub_merchant][:registered_business]
      attr_hash[:business] = {
        legal_name: params[:sub_merchant][:legal_name],
        tax_id: params[:sub_merchant][:tax_id]
      }
    end
    if params[:sub_merchant][:payout_type] == "bank"
      attr_hash[:funding] = {
        destination: params[:sub_merchant][:payout_type],
        account_number: params[:sub_merchant][:account_number],
        routing_number: params[:sub_merchant][:routing_number]
      }
    elsif params[:sub_merchant][:payout_type] == "mobile_phone"
      attr_hash[:funding] = {
        destination: params[:sub_merchant][:payout_type],
        mobile_phone: params[:sub_merchant][:venmo_mobile_phone]
      }
    else
      attr_hash[:funding] = {
        destination: params[:sub_merchant][:payout_type],
        email: params[:sub_merchant][:venmo_email]
      }
    end

    result = Braintree::MerchantAccount.update(@teacher[:merchant_account_id], attr_hash)
    if result.success?
      if @subm.update_attributes(sub_merchant_params)
        @subm[:date_of_birth] = attr_hash[:individual][:date_of_birth]
        begin
          @subm.save
        rescue e
          puts "RAILS_ERROR: #{e}"
        end
        flash[:notice] = "Your information was sent to Braintree successfully!"
        return redirect_to teachers_path
      else
        flash[:notice] = "Your Braintree information was sent, but we failed to save the record on our server. Please contact Yogalit directly."
        return redirect_to teachers_path
      end
    else
      render "edit"
    end
  end

  def split_dob(dob_split)
    @dob_year = dob_split[0]
    @dob_month = dob_split[1]
    @dob_day = dob_split[2]
  end

  def save_sub_merchant(dob, teacher_id)
    subm = SubMerchant.new(sub_merchant_params)
    subm.teacher_id = teacher_id
    subm.date_of_birth = dob
    begin
      subm.save!
    rescue e
      puts "RAILS_ERROR: #{e}"
    end
  end

  private

  def sub_merchant_params
    params.require(:sub_merchant).permit(:first_name, :last_name, :email, :phone, :date_of_birth, :street_address, :locality, :region, :postal_code, :payout_type, :registered_business, :legal_name)
  end

end
