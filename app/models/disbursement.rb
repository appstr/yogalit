class Disbursement < ActiveRecord::Base
  has_many :transactions
  has_many :disputes
end
