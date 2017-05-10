class PaymentsController < ApplicationController
  before_action :authenticate_user!
  require "opentok"

  def new
    @search_params = JSON.parse(params[:search_params])
    @session_time = parse_session_time
    @teacher = Teacher.find(@search_params["id"])
    get_teacher_price_and_sales_tax
  end

  def create
    @search_params = JSON.parse(params["search_params"])
    credit_card_processed = Payment.payment_processed?(get_credit_card_params, params[:total_price].to_s, get_billing_address_params)
    if credit_card_processed[0]
      transaction_id = credit_card_processed[1]
      @student = Student.where(user_id: current_user).first
      @teacher = Teacher.find(@search_params["id"])
      payment = Payment.new
      payment[:teacher_id] = @teacher[:id]
      payment[:student_id] = @student[:id]
      payment[:sales_tax] = params[:sales_tax]
      payment[:price_without_tax] = params[:price_without_tax]
      payment[:total_price] = params[:total_price]
      payment[:yogalit_tax] = ENV["yogalit_tax_amount"].to_f
      payment[:yogalit_fee_amount] = @yogalit_fee_amount
      payment[:teacher_payout_amount] = @teacher_payout_amount
      payment[:transaction_id] = transaction_id
      get_payout_params
      if payment.save!
        if create_open_tok_session
          if create_teacher_booked_time
            yoga_session = YogaSession.new
            yoga_session[:payment_id] = payment[:id]
            yoga_session[:teacher_id] = @teacher[:id]
            yoga_session[:student_id] = @student[:id]
            yoga_session[:teacher_booked_time_id] = @booked_time[:id]
            yoga_session[:session_date_time] = @session_date
            yoga_session[:yoga_type] = YogaType::ENUMS[@search_params["yoga_type"]]
            yoga_session[:teacher_payout_made] = false
            yoga_session[:video_under_review] = false
            yoga_session[:video_reviewed] = false
            yoga_session[:student_requested_refund] = false
            yoga_session[:student_refund_given] = false
            yoga_session[:opentok_session_id] = @opentok_session_id
            if yoga_session.save!
              flash[:notice] = "Your Yoga Session was booked successfully!"
              create_favorite_teacher_for_student(yoga_session[:teacher_id], yoga_session[:student_id])
              return redirect_to payment_path(id: yoga_session)
            else
              flash[:notice] = "Yoga Session did not save."
              return redirect_to request.referrer
            end
          else
            flash[:notice] = "Teacher Booked Time did not save."
            return redirect_to request.referrer
          end
        else
          flash[:notice] = "OpenTok session did not process"
          return redirect_to request.referrer
        end
      else
        flash[:notice] = "Payment did not save."
        return redirect_to request.referrer
      end
      return payment_path(id: 1)
    else
      flash[:notice] = credit_card_processed[1]
      return redirect_to request.referrer
    end
  end

  def show
    @yoga_session = YogaSession.find(params[:id])
  end

  private

  def get_payout_params
    @yogalit_fee_amount = params[:total_price].to_f * (ENV["yogalit_tax_amount"].to_f * 0.01)
    @teacher_payout_amount = params[:total_price].to_f - @yogalit_fee_amount
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
    booked_time[:duration] = @search_params["duration"].to_i
    booked_time[:student_timezone] = @search_params["student_timezone"]
    booked_time[:teacher_timezone] = @search_params["teacher_timezone"]
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
    Time.zone = @search_params["student_timezone"]
    date = Date.parse(@search_params["session_date"])
    year = date.strftime("%Y")
    month = date.strftime("%m")
    day = date.strftime("%d")
    @session_date = Time.zone.local(year, month, day, @start_hour, @start_minute).in_time_zone(@search_params["teacher_timezone"])
  end

  def get_session_time_range
    Time.zone = @search_params["student_timezone"]
    if @search_params["day_of_week"] == "Monday"
      month = 3
      day = 27
    elsif @search_params["day_of_week"] == "Tuesday"
      month = 3
      day = 28
    elsif @search_params["day_of_week"] == "Wednesday"
      month = 3
      day = 29
    elsif @search_params["day_of_week"] == "Thursday"
      month = 3
      day = 30
    elsif @search_params["day_of_week"] == "Friday"
      month = 3
      day = 31
    elsif @search_params["day_of_week"] == "Saturday"
      month = 4
      day = 1
    else
      month = 4
      day = 2
    end
    @time_range = (Time.zone.local(2017, month, day, @start_hour, @start_minute, 00).in_time_zone(@search_params["teacher_timezone"]).to_i..Time.zone.local(2017, month, day, @end_hour, @end_minute, 00).in_time_zone(@search_params["teacher_timezone"]).to_i)
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
    @total_price = @price_without_tax + tax_amount
  end

  def parse_session_time
    split_time = params["session_time"].split("..")
    return DateTime.parse(split_time[0])..DateTime.parse(split_time[1])
  end
end
