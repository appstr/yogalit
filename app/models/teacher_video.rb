class TeacherVideo < ActiveRecord::Base
  belongs_to :teacher

  has_attached_file :video,
                :storage => :s3,
                :styles => {
                  :medium => { :geometry => "640x480", :format => 'flv' },
                  :thumb => { :geometry => "100x100#", :format => 'jpg', :time => 10 }
                },
                :processors => [:ffmpeg],
                :convert_options => { :all => "-quality 100" },
                url: ":s3_domain_url",
                path: "/video/:id/:filename",
                s3_region: ENV["AWS_REGION"],
                default_url: "/videos/:style/missing.png",
                :s3_credentials => Proc.new{|a| a.instance.s3_credentials }

  def s3_credentials
    {:bucket => ENV["AWS_BUCKET"], :access_key_id => ENV["AWS_ACCESS_KEY_ID"], :secret_access_key => ENV["AWS_ACCESS_KEY_ID"]}
  end

  validates_attachment_content_type :video, content_type: /\Avideo\/.*\Z/
end
