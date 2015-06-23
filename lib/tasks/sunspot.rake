namespace :sunspot do
  task :sunspot do
    task :incremental_reindex do
      model = ENV['MODEL_NAME']
      raise 'Model not found' unless defined?(model)
      model.constantize.find_in_batches do |records|
        Sunspot.index records
      end
    end
  end
end
