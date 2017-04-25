class YogaTypesController < ApplicationController
  before_action :authenticate_user!
  def create
    teacher = Teacher.where(user_id: current_user).first
    teacher_yoga_types = YogaType.where(teacher_id: teacher)
    teacher_yoga_types.delete_all if !teacher_yoga_types.empty?
    if !params[:yoga_types].blank?
      params[:yoga_types].each do |k, v|
        yoga_type = YogaType.new
        yoga_type[:teacher_id] = teacher[:id]
        yoga_type[:type_id] = v.to_i
        yoga_type.save!
      end
    end
    Teacher.qualifies_for_search?(current_user)
    return redirect_to request.referrer
  end
end
