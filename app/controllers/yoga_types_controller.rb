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
        if yoga_type.save!
          flash[:notice] = "Your available Yoga Types have been updated!"
        else
          flash[:notice] = "Your available Yoga Types were not updated, please try again."
        end
      end
    end
    Teacher.qualifies_for_search?(current_user)
    return redirect_to teachers_path(section: "yoga_types")
  end
end
