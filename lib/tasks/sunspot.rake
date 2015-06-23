namespace :sunspot do
  namespace :sunspot do
    desc 'Incementaly reindex a givel model'
    task incremental_reindex: :environment do
      model = ENV['MODEL_NAME']
      raise 'Model not found' unless defined?(model)
      model.constantize.find_in_batches do |records|
        Sunspot.index records
      end
    end
  end
end
