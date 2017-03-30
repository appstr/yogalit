class TeachersController < ApplicationController
  before_action :authenticate_user!

  def index
    @teacher = Teacher.where(user_id: current_user).first
    # Returns an array of type_ids associated to the Teacher --> @type_ids
    get_teacher_yoga_types
    # Teacher Images
    @teacher_image = TeacherImage.new
    @teacher_images = TeacherImage.where(teacher_id: @teacher)
    # Teacher Videos
    @teacher_video = TeacherVideo.new
    @teacher_videos = TeacherVideo.where(teacher_id: @teacher)
  end

  def new
    @teacher = Teacher.new
  end

  def create
    teacher = Teacher.new(teacher_params)
    teacher[:user_id] = current_user[:id]
    path = teacher.save! ? teachers_path : request.referrer
    return redirect_to path
  end

  def edit
    @teacher = Teacher.where(user_id: current_user).first
  end

  def update
    teacher = Teacher.new(teacher_params)
    teacher_update = Teacher.where(user_id: current_user).first
    teacher_update[:first_name] = teacher[:first_name]
    teacher_update[:last_name] = teacher[:last_name]
    teacher_update[:phone] = teacher[:phone]
    teacher_update[:timezone] = teacher[:timezone]
    if teacher_update.save!
      flash[:notice] = "Your profile info was update successfully!"
      path = root_path
    else
      flash[:notice] = "Your profile info was not updated."
      path = request.referrer
    end
    return redirect_to path
  end

  # TODO Delete will Blacklist a user. Need to create Blacklist for Teachers.

  private

  def teacher_params
    params.require(:teacher).permit(:user_id, :first_name, :last_name, :phone, :timezone)
  end

  def get_teacher_yoga_types
    yoga_types = YogaType.where(teacher_id: @teacher)
    @type_ids = []
    yoga_types.each do |yt|
      @type_ids << yt.type_id
    end
  end

end
