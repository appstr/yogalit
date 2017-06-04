class TeacherImagesController < ApplicationController
  before_action :authenticate_user!
  def create
    teacher_image = TeacherImage.new(teacher_image_params)
    teacher_image[:teacher_id] = Teacher.where(user_id: current_user).first.id
    if teacher_image.save!
      flash[:notice] = "Your image was saved successfully!"
    else
      flash[:notice] = "Ahh, something went wrong and your image didn't save. Please try again."
    end
    return redirect_to teachers_path(section: "photos_and_videos")
  end

  def destroy
    teacher = Teacher.where(user_id: current_user).first
    teacher_image = TeacherImage.where(id: params[:id], teacher_id: teacher).first
    teacher_image.image = nil
    teacher_image.save!
    teacher_image.delete
    return redirect_to teachers_path(section: "photos_and_videos")
  end

  private

  def teacher_image_params
    params.require(:teacher_image).permit(:teacher_id, :image)
  end
end
