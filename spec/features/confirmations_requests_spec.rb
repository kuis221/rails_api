# encoding: utf-8

require 'rails_helper'

feature "Confirmations", :js => true do
  before do
    @user = FactoryGirl.create(:user,
      first_name: 'Pedro',
      last_name: 'Picapiedra',
      email: 'pedro@rocadura.com',
      unconfirmed_email: 'pedro123@rocadura.com',
      phone_number: '(506)22728899',
      country: 'CR',
      state: 'SJ',
      city: 'Curridabat',
      street_address: 'This is the street address',
      unit_number: 'This is the unit number',
      zip_code: '90210',
      confirmation_token: 'XYZ123',
      role_id: FactoryGirl.create(:role).id,
      company_id: FactoryGirl.create(:company).id
    )
  end

  scenario "should allow the user to confirm the email change and log him in after that" do
    visit users_confirmation_path(confirmation_token: 'XYZ123')

    expect(page).to have_content('Your account was successfully confirmed.')
    expect(current_path).to eq(new_user_session_path)

    @user.reload
    expect(@user.email).to eq('pedro123@rocadura.com')
    expect(@user.unconfirmed_email).to eq(nil)
    expect(@user.confirmation_token).to eq(nil)
  end
end