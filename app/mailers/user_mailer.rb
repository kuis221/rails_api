class UserMailer < ActionMailer::Base
  default from: "info@brandscopic.com"

  def password_generation(user)
    @user = user
    @url  = "http://example.com/login"
    mail(:to => user.email, :subject => "Welcome to My Awesome Site")
  end
end
