# encoding: utf-8

require 'spec_helper'

feature "Passwords", :js => true do
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

  scenario "should display an error message when email address is not found in the database" do
    visit new_user_password_path
    expect(find_field('user[email]').value).to eq('')
    fill_in('user[email]', with: 'ramdom@email.com')
    click_button 'Reset'
    expect(current_path).to eq(user_password_path)
    expect(page).to have_content("We couldn't find that email address.  Please check that you spelled it correctly and try again.")
  end

  scenario "should send an email when email address is found for existing user" do
    visit new_user_password_path
    expect(find_field('user[email]').value).to eq('')
    fill_in('user[email]', with: 'test@email.com')
    click_button 'Reset'
    expect(current_path).to eq(passwords_thanks_path)
    expect(page).to have_content("You will receive an email with instructions about how to reset your password in a few minutes.")
  end
end