class UserMailer < ActionMailer::Base
  default from: "noreply@brandscopic.com"

  def company_invitation(user, company, inviter)
    @user = user
    @company = company
    @inviter = inviter
    @url  = root_url
    mail(:to => @user.email, :subject => "Brandscopic Invitation")
  end

  def company_admin_invitation(user)
    @user = user
    @url  = root_url
    mail(:to => @user.email, :subject => "Brandscopic Invitation")
  end

  def company_existing_admin_invitation(user, company)
    @user = user
    @company = company
    @url  = root_url
    mail(:to => @user.email, :subject => "Brandscopic Invitation")
  end
end
