class Lock < ActiveRecord::Base
  belongs_to :environment
  belongs_to :app
  belongs_to :user
end
