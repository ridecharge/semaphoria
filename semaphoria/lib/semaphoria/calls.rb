module Semaphoria
  module Calls

    def lock_status(app_name, env_name)
      resp = self.agent.fetch({
        :verb => :get,
        :action => '/lock_status',
        :fields => {:app => app_name, :environment => env_name}
      })
    end

    def lock(app_name, env_name, user_name)
      resp = self.agent.fetch({
        :verb => :post,
        :action => '/lock',
        :fields => {:app => app_name, :environment => env_name, :user => user_name}
      })
    end

    def unlock(app_name, env_name)
      resp = self.agent.fetch({
        :verb => :delete,
        :action => '/lock',
        :fields => {:app => app_name, :environment => env_name}
      })
    end

  end
end