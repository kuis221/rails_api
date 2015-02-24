class JbbWorker
  @queue = :jbb_synch

  def self.perform(klass)
    klass.constantize.new.process
  end
end
