require 'rails_helper'

feature "Login", :js => true do
  scenario "should redirect the user to the login page" do
    visit root_path

    expect(current_path).to eq(new_user_session_path)
    expect(page).to have_content("You need to sign in or sign up before continuing.")
  end

  scenario "A valid user can login" do
    @company = FactoryGirl.create(:company, name: 'ABC inc.')
    user = FactoryGirl.create(:user,
      company_id: @company.id,
      email: 'pedrito-picaso@gmail.com',
      password: 'SomeValidPassword01',
      password_confirmation: 'SomeValidPassword01',
      role_id: FactoryGirl.create(:role, company: @company).id)

    visit new_user_session_path
    fill_in('user[email]', with: 'pedrito-picaso@gmail.com')
    fill_in('Password', with: 'SomeValidPassword01')
    click_button 'Login'

    expect(current_path).to eq(root_path)
    expect(page).to have_text('ABC inc.')
    expect(page).to have_text(user.full_name)
  end


  scenario "should display a message if the password is not valid" do
    visit new_user_session_path
    fill_in('user[email]', with: 'non-existing-user@gmail.com')
    fill_in('Password', with: 'SomeValidPassword01')
    click_button 'Login'

    expect(current_path).to eq(new_user_session_path)
    expect(page).to have_content('Invalid email or password.')
  end
end