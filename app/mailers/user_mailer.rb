class UserMailer < ActionMailer::Base
  default from: "noreply@brandscopic.com"

  def company_invitation(user, company, inviter)
    @user = user
    @company = company
    @inviter = inviter
    @url  = root_url
    mail(:to => @user.email, :subject => "Brandscopic Invitation")
  end
end
