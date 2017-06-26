class PaymentsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:create]
  require "opentok"
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
    student = Student.where(user_id: current_user).first
    if student[:braintree_customer_id].nil?
      result = Braintree::Customer.create(
        :first_name => student[:first_name],
        :last_name => student[:last_name],
        :email => current_user[:email],
        :phone => student[:phone],
      )
      if result.success?
        customer_id = result.customer.id
        student[:braintree_customer_id] = customer_id
        student.save!
      else
        puts result.errors
      end
    else
      customer_id = student[:braintree_customer_id]
    end
    @client_token = Braintree::ClientToken.generate(customer_id: customer_id)
    @search_params = JSON.parse(params[:search_params])
    @session_time = parse_session_time
    @teacher = Teacher.find(@search_params["id"])
    get_teacher_price_and_sales_tax
  end

  def create
    if params[:student_timezone].include?("amp;")
      params[:student_timezone] = params[:student_timezone].split("amp;").join("")
      params[:teacher_timezone] = params[:teacher_timezone].split("amp;").join("")
    end
    @student = Student.where(user_id: current_user).first
    student_email = User.find(@student[:user_id]).email
    @teacher = Teacher.find(params[:id])
    teacher_email = User.find(@teacher[:user_id]).email
    result = Braintree::Transaction.sale(
      :amount => params["total_price"],
      :payment_method_nonce => params["payload_nonce"],
      :options => {
        :submit_for_settlement => true
      }
    )
    if result.success?
      # Save Payment
      payment = Payment.new
      payment.teacher_id = @teacher
      payment.student_id = @student
      payment.sales_tax = params[:sales_tax].to_f
      payment.price_without_tax = params[:price_without_tax].to_f
      payment.total_price = params[:total_price].to_f
      get_payout_params
      payment.yogalit_tax = ENV["yogalit_tax_amount"].to_f
      payment[:yogalit_fee_amount] = @yogalit_fee_amount
      payment[:teacher_payout_amount] = @teacher_payout_amount
      payment[:transaction_id] = result.transaction.id
      begin
        payment.save!
      rescue e
        puts e
      end
      create_open_tok_session
      create_teacher_booked_time
      yoga_session = YogaSession.new
      yoga_session[:payment_id] = payment[:id]
      yoga_session[:teacher_id] = @teacher[:id]
      yoga_session[:student_id] = @student[:id]
      yoga_session[:teacher_booked_time_id] = @booked_time[:id]
      yoga_session[:yoga_type] = YogaType::ENUMS[params["yoga_type"]]
      yoga_session[:teacher_payout_made] = false
      yoga_session[:video_under_review] = false
      yoga_session[:video_reviewed] = false
      yoga_session[:teacher_cancelled_session] = false
      yoga_session[:student_requested_refund] = false
      yoga_session[:student_refund_given] = false
      yoga_session[:opentok_session_id] = @opentok_session_id
      begin
        yoga_session.save!
      rescue e
        puts e
      end
      create_favorite_teacher_for_student(yoga_session[:teacher_id], yoga_session[:student_id])
      flash[:notice] = "Payment Accepted!"
      UserMailer.new_yoga_session_booked_email(student_email, teacher_email).deliver_now
      return render json: {success: true}
    else
      flash[:notice] = "Payment Declined."
      return render json: {success: false}
    end
  end

  def show
    @yoga_session = YogaSession.find(params[:id])
  end

  def student_refund_request
    yoga_session = YogaSession.where(id: params[:id], student_id: Student.where(user_id: current_user).first.id).first
    if yoga_session[:teacher_payout_made] == true || yoga_session[:student_refund_given] == true
      flash[:notice] = "Unable to refund. Please contact Yogalit directly."
      return redirect_to request.referrer
    end
    bt = TeacherBookedTime.find(yoga_session[:teacher_booked_time_id])
    Time.zone = bt[:teacher_timezone]
    time = Time.at(bt[:time_range].first).in_time_zone(bt[:teacher_timezone])
    pd = Time.parse(bt[:session_date].to_s)
    start_time = Time.zone.local(pd.strftime("%Y"), pd.strftime("%m"), pd.strftime("%d"), time.strftime("%k"), time.strftime("%M"), 00).in_time_zone(bt[:student_timezone])
    now = Time.now.in_time_zone(bt[:student_timezone])
    if now < (start_time - 86400)
      transaction_id = Payment.find(yoga_session[:payment_id]).transaction_id
      if Payment.refund_successful?(transaction_id)
        yoga_session[:student_requested_refund] = true
        yoga_session[:student_refund_given] = true
        begin
          yoga_session.save!
        rescue e
          puts e
        end
        flash[:notice] = "Your Yoga Session payment has been refunded successfully!"
      else
        flash[:notice] = "There was a problem processing your refund. Please try again or contact Yogalit directly."
      end
    else
      flash[:notice] = "Yoga Session must be more than 24/hrs away. Please contact Yogalit directly if there is an error."
    end
    return redirect_to request.referrer
  end

  def refund_yoga_session
    yoga_session = YogaSession.find(params[:id])
    payment = Payment.find(yoga_session[:payment_id])
    transaction_id = payment[:transaction_id]
    if Payment.refund_successful?(transaction_id)
      yoga_session[:video_under_review] = false
      yoga_session[:video_reviewed] = true
      yoga_session[:student_refund_given] = true
      if yoga_session.save!
        student = Student.find(yoga_session[:student_id])
        student_email = User.find(student[:user_id]).email
        UserMailer.student_refund_email(student_email).deliver_now
        flash[:notice] = "Refund processed successfully!"
        return redirect_to request.referrer
      end
    end
    flash[:notice] = "Refund DID NOT process successfully."
    return redirect_to request.referrer
  end

  def general_refund_denial
    yoga_session = YogaSession.find(params[:id])
    yoga_session[:video_under_review] = false
    yoga_session[:video_reviewed] = true
    yoga_session[:student_refund_given] = false
    if yoga_session.save!
      student = Student.find(yoga_session[:student_id])
      student_email = User.find(student[:user_id]).email
      UserMailer.general_refund_denial(student_email).deliver_now
      flash[:notice] = "Student refund denial info saved!"
    else
      flash[:notice] = "Student refund denial info did not save."
    end
    return redirect_to request.referrer
  end

  def custom_refund_denial
    yoga_session = YogaSession.find(params[:id])
    yoga_session[:video_under_review] = false
    yoga_session[:video_reviewed] = true
    yoga_session[:student_refund_given] = false
    if yoga_session.save!
      message = "My Custom Refund Denial Message"
      student = Student.find(yoga_session[:student_id])
      student_email = User.find(student[:user_id]).email
      UserMailer.general_refund_denial(student_email, message).deliver_now
      flash[:notice] = "Student refund denial info saved!"
    else
      flash[:notice] = "Student refund denial info did not save."
    end
    return redirect_to request.referrer
  end

  private

  def get_payout_params
    @yogalit_fee_amount = (params[:total_price].to_f * (ENV["yogalit_tax_amount"].to_f * 0.01)).round(2)
    @teacher_payout_amount = (params[:total_price].to_f - @yogalit_fee_amount).round(2)
  end

  def create_favorite_teacher_for_student(teacher_id, student_id)
    if FavoriteTeacher.where(student_id: student_id, teacher_id: teacher_id).first.nil?
      favorite_teacher = FavoriteTeacher.new
      favorite_teacher[:student_id] = student_id
      favorite_teacher[:teacher_id] = teacher_id
      favorite_teacher.save!
    end
  end

  def create_teacher_booked_time
    get_session_times
    get_session_date_in_teacher_tz
    get_session_time_range
    booked_time = TeacherBookedTime.new
    booked_time[:teacher_id] = @teacher[:id]
    booked_time[:student_id] = @student[:id]
    booked_time[:session_date] = @session_date
    booked_time[:time_range] = @time_range
    booked_time[:duration] = params["duration"].to_i
    booked_time[:student_timezone] = params["student_timezone"]
    booked_time[:teacher_timezone] = params["teacher_timezone"]
    booked_time[:teacher_rating_given] = false
    if booked_time.save!
      @booked_time = booked_time
      return true
    else
      return false
    end
  end

  def get_session_times
    split_session_time = params["session_time"].split("..")

    start_time = DateTime.parse(split_session_time[0])
    @start_hour = start_time.strftime("%k").to_i
    @start_minute = start_time.strftime("%M").to_i

    end_time = DateTime.parse(split_session_time[1])
    @end_hour = end_time.strftime("%k")
    @end_minute = end_time.strftime("%M")
  end

  def get_session_date_in_teacher_tz
    Time.zone = params["student_timezone"]
    date = Date.parse(params["session_date"])
    year = date.strftime("%Y")
    month = date.strftime("%m")
    day = date.strftime("%d")
    @session_date = Time.zone.local(year, month, day, @start_hour, @start_minute).in_time_zone(params["teacher_timezone"])
  end

  def get_session_time_range
    session_split = params[:session_time].split("..")
    @time_range = Time.parse(session_split.first)..(Time.parse(session_split.last) + 60)
  end

  def create_open_tok_session
    opentok = OpenTok::OpenTok.new ENV["opentok_api_key"], ENV["opentok_api_secret"]
    session = opentok.create_session :archive_mode => :always, :media_mode => :routed
    @opentok_session_id = session.session_id
    if @opentok_session_id.nil?
      return false
    else
      return true
    end
  end

  def get_credit_card_params
    return {
      first_name: params[:cc_first_name],
      last_name: params[:cc_last_name],
      card_number: params[:cc_number],
      exp_month: params[:month],
      exp_year: params[:year],
      security_code: params[:verification_value],
      card_type: params[:card_type]
    }
  end

  def get_billing_address_params
    return {
      street_address: params[:billing_street_address],
      city: params[:billing_city],
      state: params[:billing_state],
      postal: params[:billing_postal],
    }
  end

  def get_teacher_price_and_sales_tax
    teacher_pr = TeacherPriceRange.where(teacher_id: @teacher).first
    if @search_params["duration"] == "30"
      price_and_tax = [teacher_pr[:thirty_minute_session], teacher_pr[:sales_tax]]
    elsif @search_params["duration"] == "60"
      price_and_tax = [teacher_pr[:sixty_minute_session], teacher_pr[:sales_tax]]
    else
      price_and_tax = [teacher_pr[:ninety_minute_session], teacher_pr[:sales_tax]]
    end
    @sales_tax = price_and_tax[1].to_f
    @price_without_tax = price_and_tax[0].to_f
    tax_amount = @price_without_tax * (@sales_tax * 0.01)
    @total_price = (@price_without_tax + tax_amount).round(2)
  end

  def parse_session_time
    if @search_params["student_time_frame"].nil?
      Time.zone = @search_params["student_timezone"]
      date = Time.parse(@search_params["session_date"])
      split_time_frame = @search_params["time_frame"].split(" - ")
      start_t = Time.parse(split_time_frame.first, date)
      end_t = Time.parse(split_time_frame.last, date)
      split_time = [Time.zone.local(date.strftime("%Y"), date.strftime("%m"), date.strftime("%d"), start_t.strftime("%k"), start_t.strftime("%M")), Time.zone.local(date.strftime("%Y"), date.strftime("%m"), date.strftime("%d"), end_t.strftime("%k"), end_t.strftime("%M"))]
      return split_time.first..split_time.last
    else
      split_time = @search_params["student_time_frame"].split("..")
      return DateTime.parse(split_time[0])..DateTime.parse(split_time[1])
    end
  end
end
