# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default("")
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  country                :string(4)
#  state                  :string(255)
#  city                   :string(255)
#  created_by_id          :integer
#  updated_by_id          :integer
#  invitation_token       :string(255)
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  current_company_id     :integer
#  time_zone              :string(255)
#  detected_time_zone     :string(255)
#  phone_number           :string(255)
#  street_address         :string(255)
#  unit_number            :string(255)
#  zip_code               :string(255)
#  authentication_token   :string(255)
#  invitation_created_at  :datetime
#

require 'spec_helper'

describe User do
  it { should have_many(:company_users) }

  it { should allow_value('guilleva@gmail.com').for(:email) }

  it { should allow_value("Avalidpassword1").for(:password) }
  it { should allow_value("validPassw0rd").for(:password) }
  it { should_not allow_value('Invalidpassword').for(:password).with_message(/should have at least one digit/) }
  it { should_not allow_value('invalidpassword1').for(:password).with_message(/should have at least one upper case letter/) }
  it { should validate_confirmation_of(:password) }
  it { should_not validate_presence_of(:detected_time_zone) }

  describe "email uniqness" do
    before do
      @user = FactoryGirl.create(:user)
    end
    it { should validate_uniqueness_of(:email) }
  end

  describe "validations when inviting user" do
    context do
      before { subject.inviting_user = true }
      it { should_not validate_presence_of(:country) }
      it { should_not validate_presence_of(:state) }
      it { should_not validate_presence_of(:city) }
      it { should_not validate_presence_of(:time_zone) }
      it { should_not validate_presence_of(:password) }
    end
  end

  describe "validations when editing another user" do
    context do
      before { subject.updating_user = true }
      it { should_not validate_presence_of(:phone_number) }
      it { should_not validate_presence_of(:country) }
      it { should_not validate_presence_of(:state) }
      it { should_not validate_presence_of(:city) }
      it { should_not validate_presence_of(:street_address) }
      it { should_not validate_presence_of(:city) }
      it { should_not validate_presence_of(:zip_code) }
      it { should_not validate_presence_of(:password) }
    end
  end

  describe "validations when accepting an invitation" do
    context do
      before do
        subject.invitation_accepted_at = nil
        subject.accepting_invitation = true
      end
      it { should validate_presence_of(:country) }
      it { should validate_presence_of(:state) }
      it { should validate_presence_of(:city) }
      it { should validate_presence_of(:time_zone) }
      it { should validate_presence_of(:password) }
    end
  end

  describe "validations when editing a user" do
    context do
      before do
        subject.invitation_accepted_at = Time.now
      end
      it { should validate_presence_of(:country) }
      it { should validate_presence_of(:state) }
      it { should validate_presence_of(:city) }
      it { should validate_presence_of(:time_zone) }
      it { should_not validate_presence_of(:password) }
    end
  end

  describe "#full_name" do
    let(:user) { FactoryGirl.build(:user, :first_name => 'Juanito', :last_name => 'Perez') }

    it "should return the first_name and last_name concatenated" do
      user.full_name.should == 'Juanito Perez'
    end

    it "should return only the first_name if it doesn't have last_name" do
      user.last_name = nil
      user.full_name.should == 'Juanito'
    end

    it "should return only the last_name if it doesn't have first_name" do
      user.first_name = nil
      user.full_name.should == 'Perez'
    end
  end

  describe "#country_name" do
    it "should return the correct country name" do
      user = FactoryGirl.build(:user, country: 'US')
      user.country_name.should == 'United States'
    end

    it "should return nil if the user doesn't have a country" do
      user = FactoryGirl.build(:user, country: nil)
      user.country_name.should be_nil
    end

    it "should return nil if the user has an invalid country" do
      user = FactoryGirl.build(:user, country: 'XYZ')
      user.country_name.should be_nil
    end
  end

  describe "#state_name" do
    it "should return the correct state name" do
      user = FactoryGirl.build(:user, country: 'US', state: 'FL')
      user.state_name.should == 'Florida'
    end

    it "should return nil if the user doesn't have a state" do
      user = FactoryGirl.build(:user, country: 'US', state: nil)
      user.state_name.should be_nil
    end

    it "should return nil if the user has an invalid state" do
      user = FactoryGirl.build(:user, country: 'US', state: 'XYZ')
      user.state_name.should be_nil
    end
  end


  describe "is_super_admin?" do
    it "should return true if the current role is admin" do
      company = FactoryGirl.build(:company)
      user    = FactoryGirl.build(:user, current_company: company, company_users: [FactoryGirl.build(:company_user, company: company, role: FactoryGirl.build(:role, is_admin: true))])
      User.current = user
      user.is_super_admin?.should be_true
    end

    it "should return false if the current role is admin" do
      company = FactoryGirl.build(:company)
      user    = FactoryGirl.build(:user, current_company: company, company_users: [FactoryGirl.build(:company_user, company: company, role: FactoryGirl.build(:role, is_admin: false))])
      User.current = user
      user.is_super_admin?.should be_false
    end
  end

end
