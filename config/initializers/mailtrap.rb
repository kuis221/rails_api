if ENV['MAILTRAP_HOST'].present?
  ActionMailer::Base.smtp_settings = {
    address: ENV['MAILTRAP_HOST'],
    port: ENV['MAILTRAP_PORT'],
    authentication: :plain,
    user_name: ENV['MAILTRAP_USER_NAME'],
    password: ENV['MAILTRAP_PASSWORD'],
    domain: 'heroku.com',
    enable_starttls_auto: true
  }
end
