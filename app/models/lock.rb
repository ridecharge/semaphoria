class Lock < ActiveRecord::Base
  belongs_to :environment
  belongs_to :app
  belongs_to :user
  after_initialize :set_status

  def set_status
    active = true if active.nil?
  end

  def release!
    self.update_attributes(:active => false)
  end
end
