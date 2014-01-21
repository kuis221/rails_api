Rails.application.config.generators do |g|
  g.test_framework :rspec, fixture: true
  g.fixture_replacement :factory_girl, dir: 'spec/factories'
  g.view_specs false
  g.helper_specs false
  g.stylesheets = false
  g.javascripts = false
  g.helper = false
  g.template_engine = :slim
  g.stylesheet_engine :scss
end
