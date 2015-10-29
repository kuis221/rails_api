# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default(TRUE)
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

require 'rails_helper'

RSpec.describe DataExtract::BrandAmbassadorsVisit, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        ['employee', 'Employee'], ['campaign_name', 'Campaign'], ['area_name', 'Area'],
        ['city', 'City'], ['visit_type', 'Visit Type'], ['description', 'Description'],
        ['start_date', 'Start Date'], ['end_date', 'End Date'], ['created_at', 'Created At'],
        ['modified_at', 'Modified At']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:campaign) { create(:campaign, name: 'Imperial FY14', company: company) }
    let(:subject) do
      described_class.new(company: company, current_user: company_user,
                    columns: %w(employee campaign_name area_name city visit_type description
                                start_date end_date created_at modified_at))
    end

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        visit_user = create(:company_user,
                            user: create(:user, first_name: 'Marty', last_name: 'McFly'),
                            company: company, role: company_user.role)
        other_user = create(:company_user,
                            user: create(:user, first_name: 'Leroy', last_name: 'Lewis'),
                            company: company, role: company_user.role)
        create(:brand_ambassadors_visit,
               visit_type: 'PTO', description: 'Test Visit description', company_user: company_user,
               start_date: '01/23/2014', end_date: '01/24/2014', campaign: campaign,
               area: create(:area, name: 'Area 1', company_id: company.to_param), city: 'Test City', company: company,
               created_at: Time.zone.local(2014, 1, 23, 9, 15), updated_at: Time.zone.local(2014, 1, 23, 9, 15))
        create(:brand_ambassadors_visit,
               visit_type: 'Brand Program', description: 'Last Visit bla bla', company_user: visit_user,
               start_date: '02/02/2015', end_date: '02/23/2015', campaign: create(:campaign, name: 'Go Pilsen', company: company),
               area: create(:area, name: 'Area 3', company_id: company.to_param), city: 'Last Test City', company: company,
               created_at: Time.zone.local(2015, 2, 02, 8, 00), updated_at: Time.zone.local(2015, 2, 02, 8, 00))
        create(:brand_ambassadors_visit,
               visit_type: 'Other', description: 'Other Visit', company_user: other_user,
               start_date: '05/03/2015', end_date: '05/03/2015', campaign: create(:campaign, name: 'My Campaign', company: company),
               area: nil, city: nil, company: company, created_at: Time.zone.local(2015, 2, 02, 8, 00),
               updated_at: Time.zone.local(2015, 2, 02, 8, 00))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['Benito Camelas', 'Imperial FY14', 'Area 1', 'Test City', 'PTO',
           'Test Visit description', '01/23/2014', '01/24/2014', '01/23/2014', '01/23/2014'],
          ['Leroy Lewis', 'My Campaign', nil, nil, 'Other', 'Other Visit',
           '05/03/2015', '05/03/2015', '02/02/2015', '02/02/2015'],
          ['Marty McFly', 'Go Pilsen', 'Area 3', 'Last Test City', 'Brand Program',
           'Last Visit bla bla', '02/02/2015', '02/23/2015', '02/02/2015', '02/02/2015']
        ]
      end

      it 'allows to filter the results' do
        subject.filters = { 'campaign' => [campaign.id + 100] }
        expect(subject.rows).to be_empty

        subject.filters = { 'campaign' => [campaign.id] }
        expect(subject.rows).to eql [
          ['Benito Camelas', 'Imperial FY14', 'Area 1', 'Test City', 'PTO',
           'Test Visit description', '01/23/2014', '01/24/2014', '01/23/2014', '01/23/2014']
        ]
      end

      it 'allows to sort the results' do
        another_visit_user = create(:company_user,
                                    user: create(:user, first_name: 'Michael', last_name: 'Jackson'),
                                    company: company, role: company_user.role)
        create(:brand_ambassadors_visit,
               visit_type: 'Formal Market Visit', description: 'Another Visit description', company_user: another_visit_user,
               start_date: '01/25/2015', end_date: '01/25/2015', campaign: create(:campaign, name: 'Tropical Lovers', company: company),
               area: create(:area, name: 'Area 2', company_id: company.to_param),
               city: 'Another Test City', company: company)

        subject.columns = %w(employee campaign_name area_name city visit_type description start_date end_date)
        subject.default_sort_by = 'start_date'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Benito Camelas', 'Imperial FY14', 'Area 1', 'Test City', 'PTO',
           'Test Visit description', '01/23/2014', '01/24/2014'],
          ['Michael Jackson', 'Tropical Lovers', 'Area 2', 'Another Test City', 'Formal Market Visit',
           'Another Visit description', '01/25/2015', '01/25/2015'],
          ['Marty McFly', 'Go Pilsen', 'Area 3', 'Last Test City', 'Brand Program',
           'Last Visit bla bla', '02/02/2015', '02/23/2015'],
          ['Leroy Lewis', 'My Campaign', nil, nil, 'Other', 'Other Visit', '05/03/2015', '05/03/2015']
        ]

        subject.default_sort_by = 'employee'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Michael Jackson', 'Tropical Lovers', 'Area 2', 'Another Test City', 'Formal Market Visit',
           'Another Visit description', '01/25/2015', '01/25/2015'],
          ['Marty McFly', 'Go Pilsen', 'Area 3', 'Last Test City', 'Brand Program',
           'Last Visit bla bla', '02/02/2015', '02/23/2015'],
          ['Leroy Lewis', 'My Campaign', nil, nil, 'Other', 'Other Visit', '05/03/2015', '05/03/2015'],
          ['Benito Camelas', 'Imperial FY14', 'Area 1', 'Test City', 'PTO',
           'Test Visit description', '01/23/2014', '01/24/2014']
        ]

        subject.default_sort_by = 'campaign_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Marty McFly', 'Go Pilsen', 'Area 3', 'Last Test City', 'Brand Program',
           'Last Visit bla bla', '02/02/2015', '02/23/2015'],
          ['Benito Camelas', 'Imperial FY14', 'Area 1', 'Test City', 'PTO',
           'Test Visit description', '01/23/2014', '01/24/2014'],
          ['Leroy Lewis', 'My Campaign', nil, nil, 'Other', 'Other Visit', '05/03/2015', '05/03/2015'],
          ['Michael Jackson', 'Tropical Lovers', 'Area 2', 'Another Test City', 'Formal Market Visit',
           'Another Visit description', '01/25/2015', '01/25/2015']
        ]

        subject.default_sort_by = 'visit_type'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Benito Camelas', 'Imperial FY14', 'Area 1', 'Test City', 'PTO',
           'Test Visit description', '01/23/2014', '01/24/2014'],
          ['Leroy Lewis', 'My Campaign', nil, nil, 'Other', 'Other Visit', '05/03/2015', '05/03/2015'],
          ['Michael Jackson', 'Tropical Lovers', 'Area 2', 'Another Test City', 'Formal Market Visit',
           'Another Visit description', '01/25/2015', '01/25/2015'],
          ['Marty McFly', 'Go Pilsen', 'Area 3', 'Last Test City', 'Brand Program',
           'Last Visit bla bla', '02/02/2015', '02/23/2015']
        ]
      end
    end
  end
end
