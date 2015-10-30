# encoding: utf-8

require 'rails_helper'

feature 'Passwords', js: true do
  before do
    Warden.test_mode!
    @user = create(:user, :invited,
                   first_name: 'First Name',
                   last_name: 'Last Name',
                   email: 'test@email.com',
                   role_id: create(:role).id,
                   company_id: create(:company).id)
  end
  after do
    Warden.test_reset!
  end

  scenario 'should display an error message when email address is not found in the database' do
    visit new_user_password_path
    expect(find_field('user[email]').value).to eq('')
    fill_in('user[email]', with: 'ramdom@email.com')
    click_button 'Reset'
    expect(current_path).to eq(user_password_path)
    expect(page).to have_content("We couldn't find that email address.  Please check that you spelled it correctly and try again.")
  end

  scenario 'should send an email when email address is found for existing user' do
    visit new_user_password_path
    expect(find_field('user[email]').value).to eq('')
    fill_in('user[email]', with: 'test@email.com')
    click_button 'Reset'
    expect(current_path).to eq(passwords_thanks_path)
    expect(page).to have_content('You will receive an email with instructions about how to reset your password in a few minutes.')
  end

  scenario 'should reset the user password' do
    visit new_user_password_path
    fill_in('user[email]', with: 'test@email.com')
    click_button 'Reset'

    expect(page).to have_content('You will receive an email with instructions about how to reset your password in a few minutes.')
    expect(current_path).to eq(passwords_thanks_path)

    visit reset_password_url_from_email
    fill_in 'New password', with: 'hola'
    fill_in 'Repeat new password', with: 'hola'
    click_button 'Change'

    # Make the password validation fails
    expect(page).to have_content('Password is too short (minimum is 8 characters)')
    expect(page).to have_content('Password should have at least one upper case letter')
    expect(page).to have_content('Password should have at least one digit')

    fill_in 'New password', with: 'Hola1234'
    fill_in 'Repeat new password', with: 'Hola1234'
    click_button 'Change'

    expect(page).to have_content('Your password was changed successfully. You are now signed in.')
    expect(current_path).to eq(root_path)

    expect(@user.reload.reset_password_token).to be_nil
  end

  def reset_password_url_from_email
    last_email.body.to_s.gsub(%r{.*href="[^"]+(/users/[^"]+reset_password_token=[^"]+)".*}, '\1')
  end
end
