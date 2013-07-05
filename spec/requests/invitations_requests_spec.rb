# encoding: utf-8

require 'spec_helper'

describe "Invitations", :js => true do
  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:invited_user,
      first_name: 'Pedro',
      last_name: 'Picapiedra',
      email: 'pedro@rocadura.com',
      country: 'CR',
      state: 'SJ',
      city: 'Curridabat',
      invitation_token: 'XYZ123',
      role_id: FactoryGirl.create(:role).id,
      company_id: FactoryGirl.create(:company).id
    )
  end
  after do
    Warden.test_reset!
  end

  it "should allow the user to complete the profile and log him in after that" do
    visit accept_user_invitation_path(invitation_token: 'XYZ123')
    find_field('First name').value.should == 'Pedro'
    find_field('Last name').value.should == 'Picapiedra'
    find_field('Email').value.should == 'pedro@rocadura.com'
    find_field('Country').value.should == 'CR'
    find_field('State').value.should == 'SJ'
    find_field('City').value.should == 'Curridabat'
    find_field('New password').value.should == ''
    find_field('Confirm your new password').value.should == ''


    fill_in('First name', with: 'Pablo')
    fill_in('Last name', with: 'Marmol')
    fill_in('Email', with: 'pablo@rocadura.com')
    select('United States', from: 'Country', match: :first)
    select('Texas', from: 'State')
    fill_in('City', with: 'Texas')
    fill_in('New password', with: 'Pablito123')
    fill_in('Confirm your new password', with: 'Pablito123')

    click_button 'Save'

    current_path.should == root_path
    page.should have_content('Your password was set successfully. You are now signed in.')
  end

  it "should validate the required fields" do
    visit accept_user_invitation_path(invitation_token: 'XYZ123')

    fill_in('First name', with: '')
    fill_in('Last name', with: '')
    fill_in('Email', with: '')
    select('', from: 'State')
    fill_in('City', with: '')
    fill_in('New password', with: '')
    fill_in('Confirm your new password', with: '')

    click_button 'Save'

    find_field('First name').should have_error('This field is required.')
    find_field('Last name').should have_error('This field is required.')
    find_field('Email').should have_error('This field is required.')
    find_field('State').should have_error('This field is required.')
    find_field('City').should have_error('This field is required.')
    find_field('New password').should have_error('This field is required.')
    find_field('Confirm your new password').should have_error('This field is required.')

    fill_in('New password', with: 'a')
    fill_in('Confirm your new password', with: 'a')

    click_button 'Save'
    find_field('New password').should have_error('Should have at least one upper case letter')

    fill_in('New password', with: 'aA')
    fill_in('Confirm your new password', with: 'aA')
    click_button 'Save'
    find_field('New password').should have_error('Should have at least one digit')

    fill_in('New password', with: 'aA1')
    fill_in('Confirm your new password', with: 'aA1')
    click_button 'Save'

    find_field('New password').should have_error('Please enter at least 8 characters.')

  end
end