# == Schema Information
#
# Table name: companies
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  timezone_support :boolean
#  settings         :hstore
#

require 'spec_helper'

describe Company, :type => :model do
  it { is_expected.to have_many(:company_users) }
  it { is_expected.to have_many(:teams) }
  it { is_expected.to have_many(:campaigns) }
  it { is_expected.to have_many(:roles) }

  it { is_expected.to validate_presence_of(:name) }

  describe "#team_member_options" do
    let(:company){ FactoryGirl.create(:company) }
    it 'should return empty if no users or teams' do
      expect(company.team_member_options).to match_array []
    end

    it 'should return all active users and teams' do
      u1 = FactoryGirl.create(:company_user, company: company,
        user: FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas'))
      u2 = FactoryGirl.create(:company_user, company: company,
        user: FactoryGirl.create(:user, first_name: 'Pablo', last_name: 'Baltodano'))
      u3 = FactoryGirl.create(:company_user, company: company,
        user: FactoryGirl.create(:user, first_name: 'Ujarrás', last_name: 'Zalomé'))

      team1 = FactoryGirl.create(:team, name: 'A-Team', company: company)
      team2 = FactoryGirl.create(:team, name: 'Team 1', company: company)
      FactoryGirl.create(:team, name: 'Inactive Team', active: false, company: company)

      expect(company.team_member_options).to eql [
        ["A-Team", "team:#{team1.id}", {:class=>"team"}],
        ["Guillermo Vargas", "company_user:#{u1.id}", {:class=>"company_user"}],
        ["Pablo Baltodano", "company_user:#{u2.id}", {:class=>"company_user"}],
        ["Team 1", "team:#{team2.id}", {:class=>"team"}],
        ["Ujarrás Zalomé", "company_user:#{u3.id}", {:class=>"company_user"}]
      ]
    end
  end

end
