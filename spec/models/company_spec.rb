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

require 'rails_helper'

describe Company, type: :model do
  it { is_expected.to have_many(:company_users) }
  it { is_expected.to have_many(:teams) }
  it { is_expected.to have_many(:campaigns) }
  it { is_expected.to have_many(:roles) }
  it { is_expected.to have_many(:custom_filters) }

  it { is_expected.to validate_presence_of(:name) }

  describe '#team_member_options' do
    let(:company) { create(:company) }
    it 'should return empty if no users or teams' do
      expect(company.team_member_options).to match_array []
    end

    it 'should return all active users and teams' do
      u1 = create(:company_user, company: company,
                                             user: create(:user, first_name: 'Guillermo', last_name: 'Vargas'))
      u2 = create(:company_user, company: company,
                                             user: create(:user, first_name: 'Pablo', last_name: 'Baltodano'))
      u3 = create(:company_user, company: company,
                                             user: create(:user, first_name: 'Ujarrás', last_name: 'Zalomé'))

      team1 = create(:team, name: 'A-Team', company: company)
      team2 = create(:team, name: 'Team 1', company: company)
      create(:team, name: 'Inactive Team', active: false, company: company)

      expect(company.team_member_options).to eql [
        ['A-Team', "team:#{team1.id}", { class: 'team' }],
        ['Guillermo Vargas', "company_user:#{u1.id}", { class: 'company_user' }],
        ['Pablo Baltodano', "company_user:#{u2.id}", { class: 'company_user' }],
        ['Team 1', "team:#{team2.id}", { class: 'team' }],
        ['Ujarrás Zalomé', "company_user:#{u3.id}", { class: 'company_user' }]
      ]
    end
  end

  describe '#late_event_end_date' do
    it 'should return the correct date when timezone_support is not enabled' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        company = build(:company, timezone_support: false)
        expect(company.late_event_end_date.strftime('%Y-%m-%d %H:%M:%S %z')).to eql '2013-07-24 23:59:59 -0700'
      end
    end
    it 'should return the correct date when timezone_support is enabled' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        company = build(:company, timezone_support: true)
        expect(company.late_event_end_date.strftime('%Y-%m-%d %H:%M:%S %z')).to eql '2013-07-24 23:59:59 +0000'
      end
    end
  end

  describe '#due_event_start_date' do
    it 'should return the correct date when timezone_support is not enabled' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        company = build(:company, timezone_support: false)
        expect(company.due_event_start_date.strftime('%Y-%m-%d %H:%M:%S %z')).to eql '2013-07-25 00:00:00 -0700'
      end
    end
    it 'should return the correct date when timezone_support is enabled' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        company = build(:company, timezone_support: true)
        expect(company.due_event_start_date.strftime('%Y-%m-%d %H:%M:%S %z')).to eql '2013-07-25 00:00:00 +0000'
      end
    end
  end

  describe '#due_event_end_date' do
    it 'should return the correct date when timezone_support is not enabled' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        company = build(:company, timezone_support: false)
        expect(company.due_event_end_date.strftime('%Y-%m-%d %H:%M:%S %z')).to eql '2013-07-26 12:13:00 -0700'
      end
    end
    it 'should return the correct date when timezone_support is enabled' do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        company = build(:company, timezone_support: true)
        expect(company.due_event_end_date.strftime('%Y-%m-%d %H:%M:%S %z')).to eql '2013-07-26 00:00:00 +0000'
      end
    end
  end
end
