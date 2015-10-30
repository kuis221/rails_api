require 'sidekiq/testing'

RSpec.configure do |config|
  config.around(:each) do |example|
    method = example.metadata[:inline_jobs] ? :inline! : :fake!
    Sidekiq::Testing.send(method) do
      Sidekiq::Worker.clear_all

      example.run
    end
  end
end
