require "spec_helper"

describe UserMailer do

  describe "#company_invitation" do
    let(:user) { mock_model(User, :first_name => 'Fulanito', :reset_password_token => 'qwerty', :email => 'fulanito@de-tal.com') }
    let(:inviter) { mock_model(User, :full_name => 'Menganito Perez') }
    let(:company) { mock_model(Company, :name => 'Tres Patitos') }
    let(:mail) { UserMailer.company_invitation(user, company, inviter) }

    #ensure that the subject is correct
    it 'renders the subject' do
      mail.subject.should == 'Brandscopic Invitation'
    end

    #ensure that the receiver is correct
    it 'renders the receiver email' do
      mail.to.should == [user.email]
    end

    #ensure that the sender is correct
    it 'renders the sender email' do
      mail.from.should == ['noreply@brandscopic.com']
    end

    #ensure that the first name appears in the email body
    it 'adds the first name to the email' do
      mail.body.encoded.should match('Hi Fulanito,')
    end

    #ensure that the @name variable appears in the email body
    it 'adds the inviter full name to the body' do
      mail.body.encoded.should match('Menganito Perez')
    end

    #ensure that the company name appears in the email body
    it 'adds the company name to the email' do
      mail.body.encoded.should match("Menganito Perez from Tres Patitos has invited you to use Brandscopic.")
    end
  end
end
