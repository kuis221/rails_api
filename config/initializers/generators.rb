Rails.application.config.generators do |g|
  g.template_engine = :slim
  g.stylesheet_engine :less
end
