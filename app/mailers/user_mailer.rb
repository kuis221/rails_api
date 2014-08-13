class UserMailer < ActionMailer::Base
  default from: "noreply@brandscopic.com"

  include Resque::Mailer

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

  def notification(user, subject, message)
    @user = user
    @message = message
    mail(:to => @user.email, :subject => "Brandscopic Alert: #{subject}")
  end
end
