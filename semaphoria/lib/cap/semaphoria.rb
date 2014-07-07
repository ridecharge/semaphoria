before "deploy" do
  if fetch(:check_lock_status, true)
    logger.info "Checking environment locks..."
    semaphore = Semaphoria::Client.new(:host => "semaphoria.herokuapp.com", :scheme => "http")
    status_response = semaphore.lock_status(fetch(:app_name), fetch(:env_name))
    if status_response.successful?
      if status_response.locked?
        response = Capistrano::CLI.ui.ask "This app:environment was locked by #{status_response.locked_by} at #{status_response.locked_at}. Are you sure you wish to deploy anyway? Type Y to continue."
        abort "exiting" unless response.chomp.upcase =="Y"
      end
    end
    #Etc.getlogin is asking the OS for the logged in user - so you could 
    #certainly spoof this; but if you're accessing devops tools you have access to the
    #code for devops tools and you could lock as whatever anyway.
    #there's no baked in authentication
    logger.info "Locking app:environment for #{Etc.getlogin} - remember to release the lock when you're done"
    status_response = semaphore.lock(fetch(:app_name), fetch(:env_name), Etc.getlogin)
    if status_response.successful?
      logger.info "Lock complete."
    else
      logger.info "Lock failed, continuing unabated."
    end
  end
end
