class TeacherVideosController < ApplicationController
  before_action :authenticate_user!
  def create
    teacher_video = TeacherVideo.new(teacher_video_params)
    teacher_video[:teacher_id] = Teacher.where(user_id: current_user).first.id
    if teacher_video.save!
      flash[:notice] = "Video Saved Successfully!"
    else
      flash[:notice] = "Video Did Not Save. Please Try Again."
    end
    return redirect_to teachers_path(section: "photos_and_videos")
  end

  def destroy
    teacher = Teacher.where(user_id: current_user).first
    teacher_video = TeacherVideo.where(id: params[:id], teacher_id: teacher).first
    teacher_video.video = nil
    teacher_video.save!
    teacher_video.delete
    return redirect_to teachers_path(section: "photos_and_videos")
  end

  private

  def teacher_video_params
    params.require(:teacher_video).permit(:teacher_id, :video)
  end

end
