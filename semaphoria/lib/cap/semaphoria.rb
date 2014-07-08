require 'semaphoria'
class Semaphoria::CapCheck < Struct.new(:app_name,:env_name,:user, :logger,:endpoint)
  def self.ask
    response = Capistrano::CLI.ui.ask "Are you sure you wish to deploy anyway? Type Y to continue."
    abort "exiting" unless response.chomp.upcase =="Y"
  end
  def self.create(cap)
    @semaphore = Off.new(cap.logger)
    return self unless cap.fetch(:semaphoria_check_lock, true)
    @semaphore=Semaphoria::CapCheck.new(cap.fetch(:app_name),cap.fetch(:env_name), Etc.getlogin, cap.logger)
    self
  end
  def self.check_lock
    @semaphore.have_lock? || @semaphore.locked?
  end
  def self.force_lock
    return if @semaphore.have_lock?
    @semaphore.lock
  end
  def self.force_unlock
    @semaphore.unlock
  end
  def self.lock_if_unlocked
    return if @semaphore.have_lock?
    ask if @semaphore.locked?
    @semaphore.lock
  end
  def self.unlock_my_lock
    return @semaphore.unlock if @semaphore.have_lock?
    @semaphore.locked?
  end


  class Off < Struct.new(:logger)
    def have_lock?
      false
    end
    def locked?
      false
    end
    def lock
      logger.info "Locking disabled, continuing unabated."
      self
    end
    def unlock
      logger.info "Locking disabled, not attempting to unlock."
      self
    end
  end
  
  
  def initialize(app_name, env_name, user,logger=Logger.new(STDOUT), endpoint=URI("http://semaphoria.herokuapp.com"))
    super(app_name, env_name, user, logger, endpoint)
    semaphore = Semaphoria::Client.new(:host => "semaphoria.herokuapp.com", :scheme => "http")
    @semaphore = Semaphoria::Client.new(:host => endpoint.host, :scheme => endpoint.scheme)
  end
  def status
    return @response if @response
    logger.info "Checking environment locks..."
    @response = @semaphore.lock_status(app_name, env_name)
  end

  def have_lock?
    if status.locked_by == user
      logger.info "You (#{user}) locked this app:environment at #{status.locked_at} - remember to release the lock when you're done."
    end
    status.locked_by == user
  end
  def locked?
    unless status.successful? #unlocked when unreachable
      logger.info "Failed to access semaphoria server, unknown lock state."
      return
    end
    if status.locked?
      logger.info "This app:environment was locked by #{status.locked_by} at #{status.locked_at}."
    else
      logger.info "This app:environment is currently unlocked."
    end
    status.locked?
  end
  def lock
    resp = @semaphore.lock(app_name, env_name, user)
    if resp.successful?
      logger.info "Locked app:environment for #{user} - remember to release the lock when you're done"
    else
      logger.info "Failed to lock app:environment for #{user}: #{resp.status} #{resp.errors.join(" ")}"
    end
    self
  end
  def unlock
    resp = @semaphore.unlock(app_name, env_name)
    logger.info "Lock released for app:environment. #{resp.status} #{resp.errors.join(" ")}"
    self
  end
end


Capistrano::Configuration.instance(:must_exist).load do
  set(:semaphoria_check_lock, fetch(:semaphoria_check_lock, fetch(:check_lock_status, true)))
  before "deploy", "semaphoria:lock"
  
  namespace "semaphoria" do
    task "check_lock" do
      Semaphoria::CapCheck.create(self).check_lock
    end
    task "lock" do
      Semaphoria::CapCheck.create(self).lock_if_unlocked
    end
    task "unlock" do
      Semaphoria::CapCheck.create(self).unlock_my_lock
    end
    task "force_unlock" do
      Semaphoria::CapCheck.create(self).force_unlock
    end
  end
end
