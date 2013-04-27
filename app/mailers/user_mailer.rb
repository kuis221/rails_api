class UserMailer < ActionMailer::Base
  default from: "noreply@brandscopic.com"

  def password_generation(user)
    @user = user
    @url  = complete_profile_url(:auth_token => @user.reset_password_token)
    mail(:to => user.email, :subject => "Brandscopic Invitation")
  end
end
