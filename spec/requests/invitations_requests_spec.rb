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
    Kpi.create_global_kpis
  end
  after do
    Warden.test_reset!
  end

  it "should allow the user to complete the profile and log him in after that" do
    visit accept_user_invitation_path(invitation_token: 'XYZ123')
    find_field('First name').value.should == 'Pedro'
    find_field('Last name').value.should == 'Picapiedra'
    find_field('Email').value.should == 'pedro@rocadura.com'
    find_field('Country', visible: false).value.should == 'CR'
    find_field('State', visible: false).value.should == 'SJ'
    find_field('City').value.should == 'Curridabat'
    find_field('New Password', match: :first).value.should == ''
    find_field('Confirm New Password').value.should == ''


    fill_in('First name', with: 'Pablo')
    fill_in('Last name', with: 'Marmol')
    fill_in('Email', with: 'pablo@rocadura.com')
    select_from_chosen('United States', from: 'Country', match: :first)
    select_from_chosen('Texas', from: 'State')
    fill_in('City', with: 'Texas')
    fill_in('New Password', with: 'Pablito123', match: :first)
    fill_in('Confirm New Password', with: 'Pablito123')

    click_button 'Save'

    current_path.should == root_path
    page.should have_content('Your password was set successfully. You are now signed in.')
  end

  it "should validate the required fields" do
    visit accept_user_invitation_path(invitation_token: 'XYZ123')

    fill_in('First name', with: '')
    fill_in('Last name', with: '')
    fill_in('Email', with: '')
    select_from_chosen('', from: 'State')
    fill_in('City', with: '')
    fill_in('New Password', with: '', match: :first)
    fill_in('Confirm New Password', with: '')

    click_button 'Save'

    find_field('First name').should have_error('This field is required.')
    find_field('Last name').should have_error('This field is required.')
    find_field('Email').should have_error('This field is required.')
    find_field('State', visible: false).should have_error('This field is required.')
    find_field('City').should have_error('This field is required.')
    find_field('New Password', match: :first).should have_error('This field is required.')
    find_field('Confirm New Password').should have_error('This field is required.')

    fill_in('New Password', with: 'a', match: :first)
    fill_in('Confirm New Password', with: 'a')

    click_button 'Save'
    find_field('New Password', match: :first).should have_error('Should have at least one upper case letter')

    fill_in('New Password', with: 'aA', match: :first)
    fill_in(' Confirm New Password', with: 'aA')
    click_button 'Save'
    find_field('New Password', match: :first).should have_error('Should have at least one digit')

    fill_in('New Password', with: 'aA1', match: :first)
    fill_in('Confirm New Password', with: 'aA1')
    click_button 'Save'

    find_field('New Password', with: 'aA1', match: :first).should have_error('Please enter at least 8 characters.')

  end
end