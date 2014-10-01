Resque.redis = REDIS

if ENV['WEB'] && !Rails.env.test?
  require 'resque/server'
  Resque::Server.class_eval do

    use Rack::Auth::Basic do |email, password|
      user = AdminUser.where(['lower(email) = ?', email]).first
      user.valid_password?(password) unless user.nil?
    end

  end
end
