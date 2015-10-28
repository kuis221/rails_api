# encoding: utf-8

require 'rails_helper'

feature 'Passwords', js: true do
  before do
    Warden.test_mode!
    @user = create(:invited_user,
                   first_name: 'First Name',
                   last_name: 'Last Name',
                   email: 'test@email.com',
                   role_id: create(:role).id,
                   company_id: create(:company).id
    )
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

    # Create a token to use it later in edit_user_password_path
    reset_token = Devise.token_generator.generate(User, :reset_password_token)
    @user.update_attribute(:reset_password_token, reset_token[1])

    visit edit_user_password_path(reset_password_token: reset_token[0])
    fill_in 'user_password', with: 'hola'
    fill_in 'user_password_confirmation', with: 'hola'
    click_button 'Change'

    # Make the password validatioin fails
    expect(page).to have_content('Password is too short (minimum is 8 characters)')
    expect(page).to have_content('Password should have at least one upper case letter')
    expect(page).to have_content('Password should have at least one digit')

    fill_in 'user_password', with: 'Hola1234'
    fill_in 'user_password_confirmation', with: 'Hola1234'
    click_button 'Change'

    @user.reload
    assert_nil @user.reset_password_token

    expect(current_path).to eq(root_path)
    expect(page).to have_content('Your password was changed successfully. You are now signed in.')
  end
end
