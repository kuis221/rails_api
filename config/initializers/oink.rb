if Rails.env.production? || Rails.env.staging? || Rails.env.demo?
  Rails.application.middleware.use( Oink::Middleware, :logger => Hodel3000CompliantLogger.new(STDOUT), :instruments => :memory)
else
  Rails.application.middleware.use Oink::Middleware
end
