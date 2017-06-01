class TeacherPriceRangesController < ApplicationController
  before_action :authenticate_user!

  def create
    if params[:teacher_price_range][:thirty_minute_session].to_f == 0.0 || params[:teacher_price_range][:sixty_minute_session].to_f == 0.0 || params[:teacher_price_range][:ninety_minute_session].to_f == 0.0 || params[:teacher_price_range][:sales_tax].to_f == 0.0
      flash[:notice] = "Invalid entry, your submission was unable to be saved."
      return redirect_to request.referrer
    end
    teacher = Teacher.where(user_id: current_user).first
    teacher_price_ranges = TeacherPriceRange.where(teacher_id: teacher).first
    teacher_price_ranges.delete if !teacher_price_ranges.nil?
    teacher_price_ranges = TeacherPriceRange.new(teacher_price_range_params)
    teacher_price_ranges[:teacher_id] = Teacher.where(user_id: current_user).first.id
    if teacher_price_ranges.valid? && teacher_price_ranges.save!
      flash[:notice] = "Your submission was saved!"
      Teacher.qualifies_for_search?(current_user)
    else
      error_message = ""
      teacher_price_ranges.errors.full_messages.each {|err| error_message << "#{err} "}
      flash[:notice] = error_message
    end
      return redirect_to request.referrer
  end

  private

  def teacher_price_range_params
    params.require(:teacher_price_range).permit(:thirty_minute_session, :sixty_minute_session, :ninety_minute_session, :sales_tax)
  end
end
