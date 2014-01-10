# == Schema Information
#
# Table name: kpis
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  kpi_type          :string(255)
#  capture_mechanism :string(255)
#  company_id        :integer
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  module            :string(255)      default("custom"), not null
#  ordering          :integer
#

require 'spec_helper'

describe Kpi do
  it { should belong_to(:company) }
  it { should have_many(:kpis_segments) }
  it { should have_many(:goals) }

  it { should validate_presence_of(:name) }
  it { should validate_numericality_of(:company_id) }

  # TODO: reject_if needs to be tested in the following line
  it { should accept_nested_attributes_for(:kpis_segments) }
  it { should accept_nested_attributes_for(:goals) }


  describe "merge_fields" do
    it "should merge the two fields into one by updating the master kpi" do
      kpi1 = FactoryGirl.create(:kpi)
      kpi2 = FactoryGirl.create(:kpi)
      campaigns = FactoryGirl.create_list(:campaign, 2, company_id: 1)
      expect {
        campaigns.each{|c| c.add_kpi(kpi1); c.add_kpi(kpi2); }
      }.to change(CampaignFormField, :count).by(4)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaigns[0].id.to_s => kpi1.id, campaigns[1].id.to_s => kpi1.id}
          })
        }.to change(CampaignFormField, :count).by(-2)
      }.to change(Kpi, :count).by(-1)

      kpi = Kpi.all.last # Get the resulting KPI
      kpi.name.should == 'New Name'
      kpi.description.should == 'a description'
    end

    it "should update the events results by keeping the value of the master kpi" do
      kpi1 = FactoryGirl.create(:kpi)
      kpi2 = FactoryGirl.create(:kpi)
      campaign = FactoryGirl.create(:campaign, company_id: 1)

      expect {
        campaign.add_kpi(kpi1)
        campaign.add_kpi(kpi2)
      }.to change(CampaignFormField, :count).by(2)

      # Enter results for both Kpis for a event
      event = FactoryGirl.create(:event, campaign: campaign, company_id: 1)
      expect {
        result = event.result_for_kpi(kpi1)
        result.value = 100

        result2 = event.result_for_kpi(kpi2)
        result2.value = 200
        event.save
      }.to change(EventResult, :count).by(2)


      expect{
        Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
          'name' => 'New Name',
          'description' => 'a description',
          'master_kpi' => {campaign.id.to_s => kpi1.id}
        })
      }.to change(EventResult, :count).by(-1)

      event.reload
      result = event.result_for_kpi(kpi1)
      result.reload
      result.value.should == 100
    end

    it "should merge two kpis that are in different campaigns kpi" do
      kpi1 = FactoryGirl.create(:kpi)
      kpi2 = FactoryGirl.create(:kpi)
      campaign1 = FactoryGirl.create(:campaign, company_id: 1)
      campaign2 = FactoryGirl.create(:campaign, company_id: 1)

      expect {
        campaign1.add_kpi(kpi1)
        campaign2.add_kpi(kpi2)
      }.to change(CampaignFormField, :count).by(2)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company_id: 1)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company_id: 1)
      expect {
        result = event1.result_for_kpi(kpi1)
        result.value = 100
        event1.save

        result2 = event2.result_for_kpi(kpi2)
        result2.value = 200
        event2.save
      }.to change(EventResult, :count).by(2)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to_not change(EventResult, :count)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      result = event1.result_for_kpi(kpi1)
      result.reload
      result.value.should == 100

      field1 = event1.campaign.form_field_for_kpi(kpi1)
      field1.should == result.form_field

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      result = event2.result_for_kpi(kpi1)
      result.reload
      result.value.should == 200
      field2 = event2.campaign.form_field_for_kpi(kpi1)
      field2.should == result.form_field
    end


    it "should merge two kpis that are in different campaigns kpi and one campaign has both of them" do
      kpi1 = FactoryGirl.create(:kpi)
      kpi2 = FactoryGirl.create(:kpi)
      campaign1 = FactoryGirl.create(:campaign, company_id: 1)
      campaign2 = FactoryGirl.create(:campaign, company_id: 1)

      expect {
        campaign1.add_kpi(kpi1)
        campaign1.add_kpi(kpi2)
        campaign2.add_kpi(kpi2)
      }.to change(CampaignFormField, :count).by(3)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company_id: 1)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company_id: 1)
      expect {
        result = event1.result_for_kpi(kpi1)
        result.value = 100
        event1.save

        result = event1.result_for_kpi(kpi2)
        result.value = 200
        event1.save

        result2 = event2.result_for_kpi(kpi2)
        result2.value = 300
        event2.save
      }.to change(EventResult, :count).by(3)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to change(EventResult, :count).by(-1)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      result = event1.result_for_kpi(kpi1)
      result.reload
      result.value.should == 100

      field1 = event1.campaign.form_field_for_kpi(kpi1)
      field1.should == result.form_field

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      result = event2.result_for_kpi(kpi1)
      result.reload
      result.value.should == 300
      field2 = event2.campaign.form_field_for_kpi(kpi1)
      field2.should == result.form_field
    end

    it "correctly merge the values for events of fields of the type :percentage" do
      kpi1 = FactoryGirl.build(:kpi, company_id: 1, kpi_type: 'percentage', name: 'My KPI')
      kpi1.kpis_segments.build(text: 'Uno')
      kpi1.kpis_segments.build(text: 'Dos')
      kpi1.save

      kpi2 = FactoryGirl.build(:kpi, company_id: 1, kpi_type: 'percentage', name: 'Other KPI')
      kpi2.kpis_segments.build(text: 'Uno')
      kpi2.kpis_segments.build(text: 'Dos')
      kpi2.save

      campaign = FactoryGirl.create(:campaign, company_id: 1)

      expect {
        campaign.add_kpi(kpi1)
        campaign.add_kpi(kpi2)
      }.to change(CampaignFormField, :count).by(2)

      # Enter results for both Kpis for a event
      event = FactoryGirl.create(:event, campaign: campaign, company_id: 1)
      expect {
        results = event.result_for_kpi(kpi1)
        results.first.value = '10'
        results.last.value = '90'

        results = event.result_for_kpi(kpi2)
        results.first.value = '35'
        results.last.value = '65'
        event.save
      }.to change(EventResult, :count).by(4)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign.id.to_s => kpi1.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to change(EventResult, :count).by(-2)

      event.reload
      event.result_for_kpi(kpi1).map(&:value).should == [10, 90]

      event.results.count.should == 2
    end

    it "correctly merge the values for events of fields of the type :count" do
      kpi1 = FactoryGirl.build(:kpi, company_id: 1, kpi_type: 'count', name: 'My KPI')
      kpi1.kpis_segments.build(text: 'Uno')
      kpi1.kpis_segments.build(text: 'Dos')
      kpi1.save

      kpi2 = FactoryGirl.build(:kpi, company_id: 1, kpi_type: 'count', name: 'Other KPI')
      kpi2.kpis_segments.build(text: 'Uno')
      kpi2.kpis_segments.build(text: 'Dos')
      kpi2.save

      campaign = FactoryGirl.create(:campaign, company_id: 1)

      expect {
        campaign.add_kpi(kpi1)
        campaign.add_kpi(kpi2)
      }.to change(CampaignFormField, :count).by(2)

      # Enter results for both Kpis for a event
      event = FactoryGirl.create(:event, campaign: campaign, company_id: 1)
      expect {
        result = event.result_for_kpi(kpi1)
        result.value = result.form_field.kpi.kpis_segments.detect{|s| s.text == 'Uno'}.id

        result = event.result_for_kpi(kpi2)
        result.value = result.form_field.kpi.kpis_segments.detect{|s| s.text == 'Dos'}.id
        event.save
      }.to change(EventResult, :count).by(2)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to change(EventResult, :count).by(-1)

      event = Event.find(event.id)
      event.result_for_kpi(kpi1).display_value.should == 'Dos'

      event.results.count.should == 1
    end

    it "correctly merge the values for events of fields of the type :count when the kpis are in differnet campaigns" do
      kpi1 = FactoryGirl.build(:kpi, company_id: 1, kpi_type: 'count', name: 'My KPI')
      kpi1.kpis_segments.build(text: 'Uno')
      kpi1.kpis_segments.build(text: 'Dos')
      kpi1.save

      kpi2 = FactoryGirl.build(:kpi, company_id: 1, kpi_type: 'count', name: 'Other KPI')
      kpi2.kpis_segments.build(text: 'Uno')
      kpi2.kpis_segments.build(text: 'Dos')
      kpi2.save

      campaign1 = FactoryGirl.create(:campaign, company_id: 1)
      campaign2 = FactoryGirl.create(:campaign, company_id: 1)

      expect {
        campaign1.add_kpi(kpi1)
        campaign2.add_kpi(kpi2)
      }.to change(CampaignFormField, :count).by(2)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company_id: 1)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company_id: 1)
      expect {
        result = event1.result_for_kpi(kpi1)
        result.value = result.form_field.kpi.kpis_segments.detect{|s| s.text == 'Uno'}.id
        event1.save

        result = event2.result_for_kpi(kpi2)
        result.value = result.form_field.kpi.kpis_segments.detect{|s| s.text == 'Dos'}.id
        event2.save
      }.to change(EventResult, :count).by(2)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to_not change(EventResult, :count)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      event1.result_for_kpi(kpi1).display_value.should == 'Uno'

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      event2.result_for_kpi(kpi1).display_value.should == 'Dos'
    end


    it "correctly merge the values for events of fields of the type :percentage when the kpis are in differnet campaigns" do
      kpi1 = FactoryGirl.build(:kpi, company_id: 1, kpi_type: 'percentage', name: 'My KPI')
      kpi1.kpis_segments.build(text: 'Uno')
      kpi1.kpis_segments.build(text: 'Dos')
      kpi1.save

      kpi2 = FactoryGirl.build(:kpi, company_id: 1, kpi_type: 'percentage', name: 'Other KPI')
      kpi2.kpis_segments.build(text: 'Uno')
      kpi2.kpis_segments.build(text: 'Dos')
      kpi2.save

      campaign1 = FactoryGirl.create(:campaign, company_id: 1)
      campaign2 = FactoryGirl.create(:campaign, company_id: 1)

      expect {
        campaign1.add_kpi(kpi1)
        campaign2.add_kpi(kpi2)
      }.to change(CampaignFormField, :count).by(2)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company_id: 1)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company_id: 1)
      expect {
        results = event1.result_for_kpi(kpi1)
        results.first.value = '33'
        results.last.value = '67'
        event1.save

        results = event2.result_for_kpi(kpi2)
        results.first.value = '44'
        results.last.value = '56'
        event2.save
      }.to change(EventResult, :count).by(4)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to_not change(EventResult, :count)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      event1.result_for_kpi(kpi1).map(&:value).should == [33, 67]

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      event2.result_for_kpi(kpi1).map(&:value).should == [44, 56]
    end

    it "should allow custom kpis with a global kpi" do
      Kpi.create_global_kpis
      kpi1 = FactoryGirl.create(:kpi)
      kpi2 = FactoryGirl.create(:kpi)
      campaign1 = FactoryGirl.create(:campaign, company_id: 1)
      campaign2 = FactoryGirl.create(:campaign, company_id: 1)

      campaign1.assign_all_global_kpis

      expect {
        campaign1.add_kpi(kpi1)
        campaign2.add_kpi(kpi2)
      }.to change(CampaignFormField, :count).by(2)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company_id: 1)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company_id: 1)
      expect {
        result = event1.result_for_kpi(kpi1)
        result.value = 100
        event1.save

        result2 = event2.result_for_kpi(kpi2)
        result2.value = 200
        event2.save
      }.to change(EventResult, :count).by(2)


      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id, Kpi.impressions.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-2)
      }.to_not change(EventResult, :count)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      result = event1.result_for_kpi(Kpi.impressions)
      result.reload
      result.value.should == 100

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      result = event2.result_for_kpi(Kpi.impressions)
      result.reload
      result.value.should == 200
    end
  end
end