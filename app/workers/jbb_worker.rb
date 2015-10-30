class JbbWorker
  include Sidekiq::Worker
  sidekiq_options queue: :jbb_synch

  def perform(klass)
    klass.constantize.new.process
  end
end
