class TeacherPriceRange < ActiveRecord::Base
  belongs_to :teacher
  validates :thirty_minute_session, format: {with: /\A[+-]?([0-9]*[.])?[0-9]+\z/}
  validates :sixty_minute_session, format: {with: /\A[+-]?([0-9]*[.])?[0-9]+\z/}
  validates :ninety_minute_session, format: {with: /\A[+-]?([0-9]*[.])?[0-9]+\z/}
  validates :sales_tax, format: {with: /\A[+-]?([0-9]*[.])?[0-9]+\z/}
end
