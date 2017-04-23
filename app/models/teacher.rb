class Teacher < ActiveRecord::Base
  belongs_to :user
  has_many :yoga_types
  has_many :teacher_holidays
  has_many :teacher_ratings
  has_many :teacher_monday_time_frames
  has_many :teacher_tuesday_time_frames
  has_many :teacher_wednesday_time_frames
  has_many :teacher_thursday_time_frames
  has_many :teacher_friday_time_frames
  has_many :teacher_saturday_time_frames
  has_many :teacher_sunday_time_frames
  has_many :teacher_images
  has_many :teacher_videos
  has_one :teacher_price_range

  has_attached_file :profile_pic,
                :storage => :s3,
                styles: { small: "500x350#" }, default_url: "/assets/default_photo_image.png",
                :s3_permissions => { :original => :private, :export => {:quality => 100} },
                :convert_options => { :all => "-quality 100" },
                url: ":s3_domain_url",
                path: "/profile_pic/:id/:filename",
                s3_region: ENV["aws_region"],
                default_url: "/images/:style/missing.png",
                :s3_credentials => Proc.new{|a| a.instance.s3_credentials }

  def s3_credentials
    {:bucket => ENV["aws_bucket"], :access_key_id => ENV["aws_access_key_id"], :secret_access_key => ENV["aws_secret_access_key"]}
  end

  validates_attachment_content_type :profile_pic, content_type: /\Aimage\/.*\Z/

  def self.teacher_exists?(current_user)
    return Teacher.where(user_id: current_user).first.nil? ? false : true
  end
end
