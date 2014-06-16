require "resque/tasks"
require 'resque/pool/tasks'


# this task will get called before resque:pool:setup
# and preload the rails environment in the pool manager
task "resque:setup" => :environment do
  require "sunspot/queue/resque"
  #Resque.before_fork = Proc.new { ActiveRecord::Base.connection.disconnect! }
  #Resque.after_fork = Proc.new { ActiveRecord::Base.establish_connection }
end

task "resque:pool:setup" do
  # close any sockets or files in pool manager
  ActiveRecord::Base.connection.disconnect!
  # and re-open them in the resque worker parent

  Resque::Pool.after_prefork do |job|
    ActiveRecord::Base.establish_connection
    Resque.redis.client.reconnect
  end
end