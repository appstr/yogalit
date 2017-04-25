class TeacherPriceRangesController < ApplicationController
  before_action :authenticate_user!

  def create
    teacher = Teacher.where(user_id: current_user).first
    teacher_price_ranges = TeacherPriceRange.where(teacher_id: teacher).first
    teacher_price_ranges.delete if !teacher_price_ranges.nil?
    teacher_price_ranges = TeacherPriceRange.new(teacher_price_range_params)
    teacher_price_ranges[:teacher_id] = Teacher.where(user_id: current_user).first.id
    teacher_price_ranges.save!
    Teacher.qualifies_for_search?(current_user)
    return redirect_to request.referrer
  end

  private

  def teacher_price_range_params
    params.require(:teacher_price_range).permit(:thirty_minute_session, :sixty_minute_session, :ninety_minute_session, :sales_tax)
  end
end
