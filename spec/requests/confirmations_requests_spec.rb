# encoding: utf-8

require 'spec_helper'

describe "Confirmations", :js => true do
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
    Kpi.destroy_all
    Kpi.create_global_kpis
  end

  it "should allow the user to confirm the email change and log him in after that" do
    visit users_confirmation_path(confirmation_token: 'XYZ123')

    current_path.should == root_path
    page.should have_content('Your account was successfully confirmed. You are now signed in.')

    @user.reload
    @user.email.should == 'pedro123@rocadura.com'
    @user.unconfirmed_email.should == nil
    @user.confirmation_token.should == nil

  end
end