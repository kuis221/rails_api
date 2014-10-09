RSpec.configure do |config|
  if ENV['CI']
    Capybara::Screenshot.autosave_on_failure = false
    config.after(:each) do |example|
      # Save screenshot to Amazon S3 on failure when running on the CI server
      if Capybara.page.current_url != '' && example.exception
        filename_prefix = Capybara::Screenshot.filename_prefix_for(:rspec, example)
        saver = Capybara::Screenshot::Saver.new(Capybara, Capybara.page, false, filename_prefix)
        saver.save

        # Save it to S3
        s3 = AWS::S3.new
        bucket = s3.buckets[ENV['S3_BUCKET_NAME']]
        obj = bucket.objects[File.basename(saver.screenshot_path)].write(File.open(saver.screenshot_path))
        example.metadata[:full_description] += "\n     Screenshot: #{obj.url_for(:read, expires: 24 * 3600 * 100)}"
      end
    end
  else # For some reason the description is not being added after upgrading to RSpec3 in dev machines
    Capybara::Screenshot.autosave_on_failure = false
    config.after(:each) do |example|
      if Capybara.page.current_url != '' && example.exception
        filename_prefix = Capybara::Screenshot.filename_prefix_for(:rspec, example)
        saver = Capybara::Screenshot::Saver.new(Capybara, Capybara.page, true, filename_prefix)
        saver.save
        example.metadata[:full_description] += "\n     Screenshot: #{saver.screenshot_path}"
      end
    end
  end
end
