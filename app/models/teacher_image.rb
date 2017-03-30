class TeacherImage < ActiveRecord::Base
  belongs_to :teacher

  has_attached_file :image,
                :storage => :s3,
                styles: { small: "500x350#" }, default_url: "/assets/default_photo_image.png",
                :s3_permissions => { :original => :private, :export => {:quality => 100} },
                :convert_options => { :all => "-quality 100" },
                url: ":s3_domain_url",
                path: "/image/:id/:filename",
                s3_region: ENV["aws_region"],
                default_url: "/images/:style/missing.png",
                :s3_credentials => Proc.new{|a| a.instance.s3_credentials }

  def s3_credentials
    {:bucket => ENV["aws_bucket"], :access_key_id => ENV["aws_access_key_id"], :secret_access_key => ENV["aws_secret_access_key"]}
  end

  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
end
