class JbbWorker
  include Sidekiq::Worker
  sidekiq_options queue: :jbb_synch, retry: false

  def perform(klass)
    klass.constantize.new.process
  end
end
