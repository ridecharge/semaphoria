require 'semaphoria'
class Semaphoria::CapCheck < Struct.new(:app_name,:env_name,:user, :logger,:endpoint)
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
  end
  def self.create(cap)
    @semaphore = Off.new(cap.logger)
    return unless cap.fetch(:semaphoria_check_lock, true)
    @semaphore=Semaphoria::CapCheck.new(cap.fetch(:app_name),cap.fetch(:env_name), Etc.getlogin, cap.logger).status
    self
  end
  def self.check_lock
    @semaphore.have_lock? || @semaphore.locked?
    self
  end
  def self.lock_if_unlocked
    return if @semaphore.have_lock?
    if @semaphore.locked?
      response = Capistrano::CLI.ui.ask "Are you sure you wish to deploy anyway? Type Y to continue."
      abort "exiting" unless response.chomp.upcase =="Y"
    end
    @semaphore.lock
  end
  def self.unlock_my_lock
    return unless @semaphore.have_lock?
    @semaphore.unlock
  end
  def self.force_unlock
    @semaphore.unlock
  end
  
  def initialize(app_name, env_name, user,logger=Logger.new(STDOUT), endpoint=URI("http://semaphoria.herokuapp.com"))
    super(app_name, env_name, user, logger, endpoint)
    semaphore = Semaphoria::Client.new(:host => "semaphoria.herokuapp.com", :scheme => "http")
    @semaphore = Semaphoria::Client.new(:host => endpoint.host, :scheme => endpoint.scheme)
  end
  def status
    logger.info "Checking environment locks..."
    @response ||= @semaphore.lock_status(app_name, env_name)
    self
  end
  def lock_status(a,e)
    status
  end
  def status_response
    status
  end
  def successful?
    true
  end
  def have_lock?
    if status.locked_by == user
      logger.info "You (#{user}) locked this app:environment at #{status_response.locked_at} - remember to release the lock when you're done."
    end
    status.locked_by == user
  end
  def locked?
    return unless status.successful? #unlocked when unreachable
    if status.locked?
    logger.info "This app:environment was locked by #{status_response.locked_by} at #{status_response.locked_at}."
    else
      logger.info "This app:environment is currently unlocked."
    end
    status.locked?
  end
  def lock(a,e,u) #change me \>
    logger.info "Locking app:environment for #{Etc.getlogin} - remember to release the lock when you're done"
    resp = @semaphore.lock(app_name, env_name, user)
    if resp.successful?
    logger.info "Locked app:environment for #{user} - remember to release the lock when you're done"
    else
      logger.info "Failed to lock app:environment for #{user}: #{resp.code} #{resp.body.inspect}"
      logger.info "Lock failed, continuing unabated."
    end
    self
  end
  def unlock
    resp = @semaphore.unlock(app_name, env_name)
    logger.info "Lock released for app:environment: #{resp.code} #{resp.body.inspect}"
    self
  end
end

set(:semaphoria_check_lock, fetch(:semaphoria_check_lock, fetch(:check_lock_status, true)))
namespace "semaphoria" do
  task "check_lock" do
    Semaphoria::CapCheck.create(cap).check_lock
  end
  task "lock" do
    Semaphoria::CapCheck.create(cap).lock_if_unlocked
  end
  task "unlock" do
    Semaphoria::CapCheck.create(cap).unlock
  end
  task "force_unlock" do
    Semaphoria::CapCheck.create(cap).force_unlock
  end
end
before "deploy", "semaphoria:lock" do
  if fetch(:check_lock_status, true)
    semaphore=Semaphoria::CapCheck.new(fetch(:app_name),fetch(:env_name), Etc.getlogin, logger)
    status_response = semaphore.lock_status(fetch(:app_name), fetch(:env_name))
    if status_response.successful?
      if status_response.locked?
        response = Capistrano::CLI.ui.ask "Are you sure you wish to deploy anyway? Type Y to continue."
        abort "exiting" unless response.chomp.upcase =="Y"
      end
    end
    #Etc.getlogin is asking the OS for the logged in user - so you could 
    #certainly spoof this; but if you're accessing devops tools you have access to the
    #code for devops tools and you could lock as whatever anyway.
    #there's no baked in authentication
    status_response = semaphore.lock(fetch(:app_name), fetch(:env_name), Etc.getlogin)
  end
end
