# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
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
#

require 'spec_helper'

describe User do
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }

  it { should allow_mass_assignment_of(:first_name) }
  it { should allow_mass_assignment_of(:last_name) }
  it { should allow_mass_assignment_of(:email) }

  it { should allow_value('guilleva@gmail.com').for(:email) }


  describe 'new user creation' do
    it 'should send a password_generation email' do
      @user = FactoryGirl.build(:user, :password => nil, :password_confirmation => nil)
      UserMailer.should_receive(:password_generation).with(@user).and_return(double(:deliver => true))
      @user.save!
    end

    it 'should generate a reset password token' do
      @user = FactoryGirl.build(:user, :reset_password_token => nil, :password => nil, :password_confirmation => nil)
      @user.save!
      @user.reset_password_token.should_not be_nil
    end

    it 'should NOT generate a reset password token if the a password is provided' do
      @user = FactoryGirl.build(:user, :password => 'AbcDEF123!', :password_confirmation => 'AbcDEF123!')
      @user.save!
      @user.reset_password_token.should be_nil
    end
  end
end
