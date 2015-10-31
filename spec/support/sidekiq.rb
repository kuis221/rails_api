require 'sidekiq/testing'

RSpec.configure do |config|
  config.around(:each) do |example|
    Sidekiq::Worker.clear_all
    method = example.metadata[:inline_jobs] ? :inline! : :fake!
    Sidekiq::Testing.send(method) do
      example.run
    end
  end
end
