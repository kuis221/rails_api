require "spec_helper"

describe UserMailer do
  describe "#password_generation" do
    let(:user) { mock_model(User, :first_name => 'Fulanito', :reset_password_token => 'qwerty', :email => 'fulanito@de-tal.com') }
    let(:mail) { UserMailer.password_generation(user) }

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

    #ensure that the @name variable appears in the email body
    it 'assigns @name' do
      mail.body.encoded.should match(user.first_name)
    end

    #ensure that the @confirmation_url variable appears in the email body
    it 'assigns @confirmation_url' do
      mail.body.encoded.should match("http://example.com/users/complete-profile\\?auth_token=qwerty")
    end
  end

  describe "#password_generation" do
    let(:user) { mock_model(User, :first_name => 'Fulanito', :reset_password_token => 'qwerty', :email => 'fulanito@de-tal.com') }
    let(:company) { mock_model(Company, :name => 'Tres Patitos') }
    let(:mail) { UserMailer.company_invitation(user, company) }

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
      mail.body.encoded.should match(user.first_name)
    end

    #ensure that the company name appears in the email body
    it 'adds the company name to the email' do
      mail.body.encoded.should match("You have been invited to use Brandscopic by Tres Patitos")
    end
  end
end
