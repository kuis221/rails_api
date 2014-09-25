require 'rails_helper'

describe Devise::SessionsController, type: :controller do
  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end
  let(:company) { create(:company) }
  describe '#create' do
    describe 'an active user' do
      before(:each) do
        @user = create(:company_user,
                                   user:    create(:user, password: 'Test12345!', password_confirmation: 'Test12345!'),
                                   company: company,
                                   role:    create(:role, company: company)).user
      end
      it 'should be able to login' do
        expect do
          post 'create', user: { email: @user.email, password: @user.password }
          @user.reload
        end.to change(@user, :last_sign_in_at)
      end
    end

    describe 'an active user with deactivated role' do
      before(:each) do
        @user = create(:company_user, user: create(:user, password: 'Test12345!', password_confirmation: 'Test12345!'), company: company, role: create(:role, company: company, active: false)).user
      end
      it 'should not be able to login' do
        expect do
          post 'create', user: { email: @user.email, password: @user.password }
          @user.reload
        end.not_to change(@user, :last_sign_in_at)
      end
    end

    describe 'an deactivated user' do
      it 'should not be able to login' do
        @user = create(:company_user, active: false, user: create(:user, password: 'Test12345!', password_confirmation: 'Test12345!'), company: company, role: create(:role, company: company)).user
        expect do
          post 'create', user: { email: @user.email, password: @user.password }
          @user.reload
        end.not_to change(@user, :last_sign_in_at)
        expect(flash[:alert]).to eq('Invalid email or password.')
      end
    end
  end
end
