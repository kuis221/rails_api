require 'spec_helper'

describe "Login", :js => true do
  it "should redirect the user to the login page" do
    visit root_path

    current_path.should == new_user_session_path
    page.should have_content("You need to sign in or sign up before continuing.")
  end

  it "should allow the user to complete the profile and log him in after that" do
    @company = FactoryGirl.create(:company, name: 'ABC inc.')
    @user = FactoryGirl.create(:user,
      company_id: @company.id,
      email: 'pedrito-picaso@gmail.com',
      password: 'SomeValidPassword01',
      password_confirmation: 'SomeValidPassword01',
      role_id: FactoryGirl.create(:role, company: @company).id)

    visit new_user_session_path
    fill_in('E-mail', with: 'pedrito-picaso@gmail.com')
    fill_in('Password', with: 'SomeValidPassword01')
    click_button 'Login'

    current_path.should == root_path
  end


  it "should display a message if the password is not valid" do
    visit new_user_session_path
    fill_in('E-mail', with: 'non-existing-user@gmail.com')
    fill_in('Password', with: 'SomeValidPassword01')
    click_button 'Login'

    current_path.should == new_user_session_path
    page.should have_content('Invalid email or password.')
  end
end