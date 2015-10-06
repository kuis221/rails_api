VCR.configure do |c|
  c.cassette_library_dir = Rails.root.join('spec', 'vcr')
  c.hook_into :webmock
  c.ignore_localhost = true

  c.allow_http_connections_when_no_cassette = true

  c.register_request_matcher :s3_file do |request_1, request_2|
    Regexp.new(URI(request_1.uri).path.gsub(/[0-9]+/, '\d+')).match(URI(request_2.uri).path) &&
    URI(request_1.uri).host == URI(request_2.uri).host
  end
end

RSpec.configure do |c|
  c.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join('/').underscore.gsub(/[^\w\/]+/, '_')
    options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    VCR.use_cassette(name, options) { example.call }
  end
end
