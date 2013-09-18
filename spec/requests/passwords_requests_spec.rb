# encoding: utf-8

require 'spec_helper'

describe "Passwords", :js => true do
  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:invited_user,
      first_name: 'First Name',
      last_name: 'Last Name',
      email: 'test@email.com',
      role_id: FactoryGirl.create(:role).id,
      company_id: FactoryGirl.create(:company).id
    )
  end
  after do
    Warden.test_reset!
  end

  it "should display an error message when email address is not found in the database" do
    visit new_user_password_path
    find_field('user[email]').value.should == ''
    fill_in('user[email]', with: 'ramdom@email.com')
    click_button 'Reset'
    current_path.should == user_password_path
    page.should have_content("We couldn't find that email address.  Please check that you spelled it correctly and try again.")
  end

  it "should send an email when email address is found for existing user" do
    visit new_user_password_path
    find_field('user[email]').value.should == ''
    fill_in('user[email]', with: 'test@email.com')
    click_button 'Reset'
    current_path.should == passwords_thanks_path
    page.should have_content("You will receive an email with instructions about how to reset your password in a few minutes.")
  end
end