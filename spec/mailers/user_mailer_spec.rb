require "spec_helper"

describe UserMailer do

  describe "#company_invitation" do
    let(:user) { double(User, :first_name => 'Fulanito', :reset_password_token => 'qwerty', :email => 'fulanito@de-tal.com') }
    let(:inviter) { double(User, :full_name => 'Menganito Perez') }
    let(:company) { double(Company, :name => 'Tres Patitos') }
    let(:mail) { UserMailer.company_invitation(user, company, inviter) }

    #ensure that the subject is correct
    it 'renders the subject' do
      expect(mail.subject).to eql 'Brandscopic Invitation'
    end

    #ensure that the receiver is correct
    it 'renders the receiver email' do
      expect(mail.to).to eql [user.email]
    end

    #ensure that the sender is correct
    it 'renders the sender email' do
      expect(mail.from).to eql ['noreply@brandscopic.com']
    end

    #ensure that the first name appears in the email body
    it 'adds the first name to the email' do
      expect(mail.body.encoded).to include('Hi Fulanito,')
    end

    #ensure that the @name variable appears in the email body
    it 'adds the inviter full name to the body' do
      expect(mail.body.encoded).to include('Menganito Perez')
    end

    #ensure that the company name appears in the email body
    it 'adds the company name to the email' do
      expect(mail.body.encoded).to include("Menganito Perez from Tres Patitos has invited you to use Brandscopic.")
    end
  end

  describe "#company_admin_invitation" do
    let(:user) { FactoryGirl.create(:user, :first_name => 'Fulanito', :reset_password_token => 'qwerty', :email => 'fulanito@de-tal.com', :invitation_token => '7d739a11e81b4f477f45a31f8f0bf119a1cb5754db0017e3bc1d6a02c5961ac0') }
    let(:mail) { UserMailer.company_admin_invitation(user) }

    #ensure that the subject is correct
    it 'renders the subject' do
      expect(mail.subject).to eql 'Brandscopic Invitation'
    end

    #ensure that the receiver is correct
    it 'renders the receiver email' do
      expect(mail.to).to eql [user.email]
    end

    #ensure that the sender is correct
    it 'renders the sender email' do
      expect(mail.from).to eql ['noreply@brandscopic.com']
    end

    #ensure that the first name appears in the email body
    it 'adds the first name to the email' do
      expect(mail.body.encoded).to include('Hi Fulanito,')
    end

    #ensure that the company name appears in the email body
    it 'adds the accept invitation link to the email' do
      expect(mail.body.encoded).to include("<a href=\"http://example.com:5100/users/invitation/accept?invitation_token=7d739a11e81b4f477f45a31f8f0bf119a1cb5754db0017e3bc1d6a02c5961ac0\">Accept invitation</a>")
    end
  end

  describe "#company_existing_admin_invitation" do
    let(:user) { double(User, :first_name => 'Fulanito', :reset_password_token => 'qwerty', :email => 'fulanito@de-tal.com') }
    let(:company) { double(Company, :name => 'Tres Patitos') }
    let(:mail) { UserMailer.company_existing_admin_invitation(user, company) }

    #ensure that the subject is correct
    it 'renders the subject' do
      expect(mail.subject).to eql 'Brandscopic Invitation'
    end

    #ensure that the receiver is correct
    it 'renders the receiver email' do
      expect(mail.to).to eql [user.email]
    end

    #ensure that the sender is correct
    it 'renders the sender email' do
      expect(mail.from).to eql ['noreply@brandscopic.com']
    end

    #ensure that the first name appears in the email body
    it 'adds the first name to the email' do
      expect(mail.body.encoded).to include('Hi Fulanito,')
    end

    #ensure that the company name appears in the email body
    it 'adds the company name to the email' do
      expect(mail.body.encoded).to include("Tres Patitos company was created in your Brandscopic account.")
    end
  end

  describe "#notification" do
    let(:user) { double(User, :first_name => 'Fulanito', :reset_password_token => 'qwerty', :email => 'fulanito@de-tal.com') }
    let(:subject) { "Rejected Event Recaps" }
    let(:message) { "You have a rejected event recap http://localhost:5100/events/10908" }
    let(:mail) { UserMailer.notification(user, subject, message) }

    #ensure that the subject is correct
    it 'renders the subject' do
      expect(mail.subject).to eql 'Brandscopic Alert: Rejected Event Recaps'
    end

    #ensure that the receiver is correct
    it 'renders the receiver email' do
      expect(mail.to).to eql [user.email]
    end

    #ensure that the sender is correct
    it 'renders the sender email' do
      expect(mail.from).to eql ['noreply@brandscopic.com']
    end

    #ensure that the first name appears in the email body
    it 'adds the first name to the email' do
      expect(mail.body.encoded).to include('Hi Fulanito,')
    end

    #ensure that the company name appears in the email body
    it 'adds the message to the email' do
      expect(mail.body.encoded).to include("You have a rejected event recap http://localhost:5100/events/10908.")
    end
  end
end
