class TeacherImage < ActiveRecord::Base
  belongs_to :teacher

  has_attached_file :image,
                :storage => :s3,
                styles: { small: "500x350#" }, default_url: "/assets/default_photo_image.png",
                :s3_permissions => { :original => :private, :export => {:quality => 100} },
                :convert_options => { :all => "-quality 100" },
                url: ":s3_domain_url",
                path: "/image/:id/:filename",
                s3_region: ENV["AWS_REGION"],
                default_url: "/images/:style/missing.png",
                :s3_credentials => Proc.new{|a| a.instance.s3_credentials }

  def s3_credentials
    {:bucket => ENV["AWS_BUCKET"], :access_key_id => ENV["AWS_ACCESS_KEY_ID"], :secret_access_key => ENV["AWS_ACCESS_KEY_ID"]}
  end

  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
end
