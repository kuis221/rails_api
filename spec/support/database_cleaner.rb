RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion, { except: ['public.spatial_ref_sys'] }
    DatabaseCleaner.clean_with(:truncation, except: ['public.spatial_ref_sys'])
    DatabaseCleaner.logger = Rails.logger
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
