class YogaTypesController < ApplicationController
  before_action :authenticate_user!
  def create
    teacher = Teacher.where(user_id: current_user).first
    YogaType.where(teacher_id: teacher).delete_all
    params[:yoga_types].each do |k, v|
      yoga_type = YogaType.new
      yoga_type[:teacher_id] = teacher[:id]
      yoga_type[:type_id] = v.to_i
      yoga_type.save!
    end
    return redirect_to request.referrer
  end
end
