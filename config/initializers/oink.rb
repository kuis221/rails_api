Rails.application.middleware.use Oink::Middleware if Rails.env.development?
