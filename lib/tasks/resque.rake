require "resque/tasks"

task "resque:setup" => :environment do
  Resque.before_fork = Proc.new { ActiveRecord::Base.connection.disconnect! }
  Resque.after_fork = Proc.new { ActiveRecord::Base.establish_connection }
 end
