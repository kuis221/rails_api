class UserMailer < ActionMailer::Base
  default from: 'noreply@brandscopic.com'

  include Resque::Mailer

  def company_invitation(user_id, company_id, inviter_id)
    @user = User.find(user_id)
    @company = Company.find(company_id)
    @inviter = User.find(inviter_id)
    @url  = root_url
    mail(to: @user.email, subject: 'Brandscopic Invitation')
  end

  def company_admin_invitation(user_id)
    @user = User.find(user_id)
    @url  = root_url
    mail(to: @user.email, subject: 'Brandscopic Invitation')
  end

  def company_existing_admin_invitation(user_id, company_id)
    @user = User.find(user_id)
    @company = Company.find(company_id)
    @url  = root_url
    mail(to: @user.email, subject: 'Brandscopic Invitation')
  end

  def notification(company_user_id, subject, message)
    @user = CompanyUser.find(company_user_id)
    @message = message
    mail(to: @user.email, subject: "Brandscopic Alert: #{subject}")
  end
end
