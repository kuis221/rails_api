# encoding: utf-8

require 'rails_helper'

feature 'Invitations', js: true do
  let(:company) { create(:company) }

  before { Warden.test_mode! }
  after { Warden.test_reset! }

  feature 'send invitation' do
    let(:user) { create(:user, company_id: company.id, role_id: create(:role).id) }

    before { sign_in user }

    scenario 'should allow the user fill the invitation form and send the invitation' do
      role = create(:role, name: 'Test role', company: company, is_admin: false)
      team = create(:team, name: 'Test team', company: company)
      visit company_users_path

      click_button 'Invite user'

      within('form#new_user') do
        fill_in('First name', with: 'Pablo')
        fill_in('Last name', with: 'Marmol')
        select_from_chosen('Test team', from: 'Teams', match: :first)
        select_from_chosen('Test role', from: 'Role', match: :first)
        fill_in('Email', with: 'pablo@rocadura.com')
        click_js_button 'Send request'
      end
      ensure_modal_was_closed

      new_user = CompanyUser.last

      expect(new_user.first_name).to eq('Pablo')
      expect(new_user.last_name).to eq('Marmol')
      expect(new_user.teams).to eq([team])
      expect(new_user.role_id).to eq(role.id)
      expect(new_user.email).to eq('pablo@rocadura.com')
    end

    scenario 'should validate the required fields' do
      visit company_users_path
      click_button 'Invite user'

      fill_in('First name', with: '')
      fill_in('Last name', with: '')
      select_from_chosen('', from: 'Role')
      fill_in('Email', with: '')

      click_button 'Send request'

      expect(find_field('First name')).to have_error('This field is required.')
      expect(find_field('Last name')).to have_error('This field is required.')
      expect(find_field('Role', visible: false)).to have_error('This field is required.')
      expect(find_field('Email')).to have_error('This field is required.')
    end

    scenario 'should validate who is not present the role admin' do
      role = create(:role, name: 'Test admin role', company: company)
      role2 = create(:role, name: 'Test not admin role', company: company, is_admin: false)

      visit company_users_path

      click_button 'Invite user'

      expect(page).to_not have_content('Test admin role')
      expect(page).to have_content('Test not admin role')
    end


  end

  feature 'accept invitation' do
    let(:user) do
      create(:invited_user,
             first_name: 'Pedro', last_name: 'Picapiedra', email: 'pedro@rocadura.com',
             phone_number: '(506)22728899', country: 'CR', state: 'SJ', city: 'Curridabat',
             street_address: 'This is the street address', unit_number: 'This is the unit number',
             zip_code: '90210', invitation_token: 'XYZ123', role_id: create(:role).id,
             company_id: create(:company).id
      )
    end

    before { user }

    scenario 'should allow the user to complete the profile and log him in after that' do
      visit accept_user_invitation_path(invitation_token: 'XYZ123')
      expect(find_field('First name').value).to eq('Pedro')
      expect(find_field('Last name').value).to eq('Picapiedra')
      expect(find_field('Email').value).to eq('pedro@rocadura.com')
      expect(find_field('Phone number').value).to eq('(506)22728899')
      expect(find_field('Country', visible: false).value).to eq('CR')
      expect(find_field('State', visible: false).value).to eq('SJ')
      expect(find_field('City').value).to eq('Curridabat')
      expect(find('#user_street_address').value).to eq('This is the street address')
      expect(find('#user_unit_number').value).to eq('This is the unit number')
      expect(find_field('Zip code').value).to eq('90210')
      expect(find_field('New Password', match: :first).value).to eq('')
      expect(find_field('Confirm New Password').value).to eq('')

      fill_in('First name', with: 'Pablo')
      fill_in('Last name', with: 'Marmol')
      fill_in('Email', with: 'pablo@rocadura.com')
      fill_in('Phone number', with: '(506)22506633')
      select_from_chosen('United States of America', from: 'Country', match: :first)
      select_from_chosen('Texas', from: 'State')
      fill_in('City', with: 'Texas')
      fill_in('user_street_address', with: 'A different street address')
      fill_in('user_unit_number', with: 'A different unit number')
      fill_in('Zip code', with: '32154')
      fill_in('New Password', with: 'Pablito123', match: :first)
      fill_in('Confirm New Password', with: 'Pablito123')

      click_button 'Save'

      expect(current_path).to eq(root_path)
      expect(page).to have_content(
        'Your password was set successfully. You are now signed in.')
    end

    scenario 'should display an error if the token is not valid' do
      visit accept_user_invitation_path(invitation_token: 'INVALIDTOKEN')
      expect(page).to have_content(
        'It looks like you\'ve already completed your profile. '\
        'Sign in using the form below or click here to reset your password.')
      expect(current_path).to eq(new_user_session_path)
    end

    scenario 'should validate the required fields' do
      visit accept_user_invitation_path(invitation_token: 'XYZ123')

      fill_in('First name', with: '')
      fill_in('Last name', with: '')
      fill_in('Email', with: '')
      fill_in('Phone number', with: '')
      select_from_chosen('', from: 'State')
      fill_in('City', with: '')
      fill_in('user_street_address', with: '')
      fill_in('Zip code', with: '')
      fill_in('New Password', with: '', match: :first)
      fill_in('Confirm New Password', with: '')

      click_button 'Save'

      expect(find_field('First name')).to have_error('This field is required.')
      expect(find_field('Last name')).to have_error('This field is required.')
      expect(find_field('Email')).to have_error('This field is required.')
      expect(find_field('State', visible: false)).to have_error('This field is required.')
      expect(find_field('City')).to have_error('This field is required.')
      expect(find_field('user_street_address')).to have_error('This field is required.')
      expect(find_field('Zip code')).to have_error('This field is required.')
      expect(find_field('New Password', match: :first)).to have_error('This field is required.')
      expect(find_field('Confirm New Password')).to have_error('This field is required.')

      fill_in('New Password', with: 'a', match: :first)
      fill_in('Confirm New Password', with: 'a')

      click_button 'Save'
      expect(find_field('New Password', match: :first)).to have_error('Should have at least one upper case letter')

      fill_in('New Password', with: 'aA', match: :first)
      fill_in('Confirm New Password', with: 'aA')
      click_button 'Save'
      expect(find_field('New Password', match: :first)).to have_error('Should have at least one digit')

      fill_in('New Password', with: 'aA1', match: :first)
      fill_in('Confirm New Password', with: 'aA1')
      click_button 'Save'

      expect(find_field('New Password', with: 'aA1', match: :first)).to have_error('Please enter at least 8 characters.')
    end
  end

  feature 'deactivated user' do
    let(:user) do
      create(:invited_user, invitation_token: 'XYZ123', invitation_sent_at: 1.days.ago, active: false,
             role_id: create(:role, company: company).id, company: company)
    end

    before { user }

    it 'should let the user know that the invitation token have expired' do

      visit accept_user_invitation_path(invitation_token: 'XYZ123')

      expect(page).to have_content(
        'Your user has been deactivated. '\
        'Please contact support@brandcopic.com if you think this has been in error.')

      expect(current_path).to eql '/users/sign_in'
    end
  end
end
