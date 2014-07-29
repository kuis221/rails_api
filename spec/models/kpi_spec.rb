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

  describe "invalid_goal?" do
    let(:company) { FactoryGirl.create(:company) }
    let(:campaign) { FactoryGirl.create(:campaign, company: company) }
    it "should return true if Goal kpis_segment_id is nil for a Kpi of type percentage" do
      kpi = FactoryGirl.create(:kpi, kpi_type: 'percentage', capture_mechanism: 'integer', company: company)
      goal = FactoryGirl.create(:goal, goalable: campaign, kpi: kpi)

      kpi.invalid_goal?(goal).should be_truthy
    end

    it "should return false if Goal has a kpis_segment_id for a Kpi of type count" do
      kpi = FactoryGirl.create(:kpi, kpi_type: 'count', capture_mechanism: 'radio', company: company, kpis_segments: FactoryGirl.create_list(:kpis_segment, 2))
      goal = FactoryGirl.create(:goal, goalable: campaign, kpi: kpi, kpis_segment_id: 100)

      kpi.invalid_goal?(goal).should be_falsey
    end

    it "should return false if Goal has a nil kpis_segment_id for a Kpi of type different to count or percentage" do
      kpi = FactoryGirl.create(:kpi, kpi_type: 'number', capture_mechanism: 'currency', company: company)
      goal = FactoryGirl.create(:goal, goalable: campaign, kpi: kpi)

      kpi.invalid_goal?(goal).should be_falsey
    end
  end

  describe "segments_count_valid?" do
    let(:company) { FactoryGirl.create(:company) }

    it "should return error if there are restrictions when capture_mechanism is radio and number od segments is less than 2" do
      kpi = FactoryGirl.build(:kpi, kpi_type: 'count', capture_mechanism: 'radio', company: company, kpis_segments: FactoryGirl.create_list(:kpis_segment, 1))
      kpi.save
      expect(kpi.persisted?).to be_falsey
      expect(kpi.errors.full_messages).to include("You need to add at least 2 segments for the selected capture mechanism")
    end

    it "should return error if there are restrictions when capture_mechanism is dropdown and number od segments is less than 1" do
      kpi = FactoryGirl.build(:kpi, kpi_type: 'count', capture_mechanism: 'dropdown', company: company)
      kpi.save
      expect(kpi.persisted?).to be_falsey
      expect(kpi.errors.full_messages).to include("You need to add at least 1 segments for the selected capture mechanism")
    end

    it "should return error if there are restrictions when capture_mechanism is checkbox and number od segments is less than 1" do
      kpi = FactoryGirl.build(:kpi, kpi_type: 'count', capture_mechanism: 'checkbox', company: company)
      kpi.save
      expect(kpi.persisted?).to be_falsey
      expect(kpi.errors.full_messages).to include("You need to add at least 1 segments for the selected capture mechanism")
    end

    it "should not return errors if capture_mechanism doesn't have segments quantity restrictions" do
      kpi = FactoryGirl.build(:kpi, kpi_type: 'number', capture_mechanism: 'decimal', company: company)
      kpi.save
      expect(kpi.persisted?).to be_truthy
      expect(kpi.errors.full_messages).to be_empty
    end
  end

  describe "merge_fields" do
    let(:company) { FactoryGirl.create(:company) }
    it "should merge the two fields into one by updating the master kpi" do
      kpi1 = FactoryGirl.create(:kpi, company: company)
      kpi2 = FactoryGirl.create(:kpi, company: company)
      campaigns = FactoryGirl.create_list(:campaign, 2, company: company)
      expect {
        campaigns.each{|c| c.add_kpi(kpi1); c.add_kpi(kpi2); }
      }.to change(FormField, :count).by(4)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaigns[0].id.to_s => kpi1.id, campaigns[1].id.to_s => kpi1.id}
          })
        }.to change(FormField, :count).by(-2)
      }.to change(Kpi, :count).by(-1)

      kpi = Kpi.all.last # Get the resulting KPI
      kpi.name.should == 'New Name'
      kpi.description.should == 'a description'
    end

    it "should update the events results by keeping the value of the master kpi" do
      kpi1 = FactoryGirl.create(:kpi, company: company)
      kpi2 = FactoryGirl.create(:kpi, company: company)
      campaign = FactoryGirl.create(:campaign, company: company)

      expect {
        campaign.add_kpi(kpi1)
        campaign.add_kpi(kpi2)
      }.to change(FormField, :count).by(2)

      # Enter results for both Kpis for a event
      event = FactoryGirl.create(:event, campaign: campaign, company: company)
      expect {
        result = event.result_for_kpi(kpi1)
        result.value = 100

        result2 = event.result_for_kpi(kpi2)
        result2.value = 200
        event.save
      }.to change(FormFieldResult, :count).by(2)


      expect{
        Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
          'name' => 'New Name',
          'description' => 'a description',
          'master_kpi' => {campaign.id.to_s => kpi1.id}
        })
      }.to change(FormFieldResult, :count).by(-1)

      event.reload
      result = event.result_for_kpi(kpi1)
      result.reload
      result.value.should == '100'
    end

    it "should merge two kpis that are in different campaigns kpi" do
      kpi1 = FactoryGirl.create(:kpi, company: company)
      kpi2 = FactoryGirl.create(:kpi, company: company)
      campaign1 = FactoryGirl.create(:campaign, company: company)
      campaign2 = FactoryGirl.create(:campaign, company: company)

      expect {
        campaign1.add_kpi(kpi1)
        campaign2.add_kpi(kpi2)
      }.to change(FormField, :count).by(2)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company: company)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company: company)
      expect {
        result = event1.result_for_kpi(kpi1)
        result.value = 100
        event1.save

        result2 = event2.result_for_kpi(kpi2)
        result2.value = 200
        event2.save
      }.to change(FormFieldResult, :count).by(2)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to_not change(FormFieldResult, :count)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      result = event1.result_for_kpi(kpi1)
      result.value.should == '100'

      field1 = event1.campaign.form_field_for_kpi(kpi1)
      field1.should == result.form_field

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      result = event2.result_for_kpi(kpi1)
      result.value.should == '200'
      field2 = event2.campaign.form_field_for_kpi(kpi1)
      field2.should == result.form_field
    end


    it "should merge two kpis that are in different campaigns kpi and one campaign has both of them" do
      kpi1 = FactoryGirl.create(:kpi, company: company)
      kpi2 = FactoryGirl.create(:kpi, company: company)
      campaign1 = FactoryGirl.create(:campaign, company: company)
      campaign2 = FactoryGirl.create(:campaign, company: company)

      expect {
        campaign1.add_kpi(kpi1)
        campaign1.add_kpi(kpi2)
        campaign2.add_kpi(kpi2)
      }.to change(FormField, :count).by(3)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company: company)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company: company)
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
      }.to change(FormFieldResult, :count).by(3)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to change(FormFieldResult, :count).by(-1)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      result = event1.result_for_kpi(kpi1)
      result.reload
      result.value.should == '100'

      field1 = event1.campaign.form_field_for_kpi(kpi1)
      field1.should == result.form_field

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      result = event2.result_for_kpi(kpi1)
      result.reload
      result.value.should == '300'
      field2 = event2.campaign.form_field_for_kpi(kpi1)
      field2.should == result.form_field
    end

    it "correctly merge the values for events of fields of the type :percentage" do
      kpi1 = FactoryGirl.build(:kpi, company: company, kpi_type: 'percentage', name: 'My KPI')
      seg11 = kpi1.kpis_segments.build(text: 'Uno')
      seg12 = kpi1.kpis_segments.build(text: 'Dos')
      kpi1.save

      kpi2 = FactoryGirl.build(:kpi, company: company, kpi_type: 'percentage', name: 'Other KPI')
      seg21 = kpi2.kpis_segments.build(text: 'Uno')
      seg22 = kpi2.kpis_segments.build(text: 'Dos')
      kpi2.save

      campaign = FactoryGirl.create(:campaign, company: company)

      expect {
        campaign.add_kpi(kpi1)
        campaign.add_kpi(kpi2)
      }.to change(FormField, :count).by(2)

      # Enter results for both Kpis for a event
      event = FactoryGirl.create(:event, campaign: campaign, company: company)
      expect {
        result = event.result_for_kpi(kpi1)
        result.value = {seg11.id => '10', seg12.id => '90'}

        result = event.result_for_kpi(kpi2)
        result.value = {seg21.id => '35', seg22.id => '65'}
        event.save
      }.to change(FormFieldResult, :count).by(2)

      expect{
        expect{
          expect{
            Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
              'name' => 'New Name',
              'description' => 'a description',
              'master_kpi' => {campaign.id.to_s => kpi1.id}
            })
          }.to change(Kpi, :count).by(-1)
        }.to change(Kpi, :count).by(-1)
      }.to change(FormFieldResult, :count).by(-1)

      event = Event.find(event.id)
      event.result_for_kpi(kpi1).value.values.should == ['10', '90']

      event.results.count.should == 1
    end

    it "correctly merge the values for events of fields of the type :count" do
      kpi1 = FactoryGirl.build(:kpi, company: company, kpi_type: 'count', name: 'My KPI')
      kpi1.kpis_segments.build(text: 'Uno')
      kpi1.kpis_segments.build(text: 'Dos')
      kpi1.save

      kpi2 = FactoryGirl.build(:kpi, company: company, kpi_type: 'count', name: 'Other KPI')
      kpi2.kpis_segments.build(text: 'Uno')
      kpi2.kpis_segments.build(text: 'Dos')
      kpi2.save

      campaign = FactoryGirl.create(:campaign, company: company)

      expect {
        campaign.add_kpi(kpi1)
        campaign.add_kpi(kpi2)
      }.to change(FormField, :count).by(2)

      # Enter results for both Kpis for a event
      event = FactoryGirl.create(:event, campaign: campaign, company: company)
      expect {
        result = event.result_for_kpi(kpi1)
        result.value = result.form_field.kpi.kpis_segments.detect{|s| s.text == 'Uno'}.id

        result = event.result_for_kpi(kpi2)
        result.value = result.form_field.kpi.kpis_segments.detect{|s| s.text == 'Dos'}.id
        event.save
      }.to change(FormFieldResult, :count).by(2)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to change(FormFieldResult, :count).by(-1)

      event = Event.find(event.id)
      event.result_for_kpi(kpi1).to_html.should == 'Dos'

      event.results.count.should == 1
    end

    it "correctly merge the values for events of fields of the type :count when the kpis are in differnet campaigns" do
      kpi1 = FactoryGirl.build(:kpi, company: company, kpi_type: 'count', name: 'My KPI')
      kpi1.kpis_segments.build(text: 'Uno')
      kpi1.kpis_segments.build(text: 'Dos')
      kpi1.save

      kpi2 = FactoryGirl.build(:kpi, company: company, kpi_type: 'count', name: 'Other KPI')
      kpi2.kpis_segments.build(text: 'Uno')
      kpi2.kpis_segments.build(text: 'Dos')
      kpi2.save

      campaign1 = FactoryGirl.create(:campaign)
      campaign2 = FactoryGirl.create(:campaign)

      expect {
        campaign1.add_kpi(kpi1)
        campaign2.add_kpi(kpi2)
      }.to change(FormField, :count).by(2)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1)
      event2 = FactoryGirl.create(:event, campaign: campaign2)
      expect {
        result = event1.result_for_kpi(kpi1)
        result.value = result.form_field.kpi.kpis_segments.detect{|s| s.text == 'Uno'}.id
        event1.save

        result = event2.result_for_kpi(kpi2)
        result.value = result.form_field.kpi.kpis_segments.detect{|s| s.text == 'Dos'}.id
        event2.save
      }.to change(FormFieldResult, :count).by(2)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to_not change(FormFieldResult, :count)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      event1.result_for_kpi(kpi1).to_html.should == 'Uno'

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      event2.result_for_kpi(kpi1).to_html.should == 'Dos'
    end


    it "correctly merge the values for events of fields of the type :percentage when the kpis are in differnet campaigns" do
      kpi1 = FactoryGirl.build(:kpi, company: company, kpi_type: 'percentage', name: 'My KPI')
      seg11 = kpi1.kpis_segments.build(text: 'Uno')
      seg12 = kpi1.kpis_segments.build(text: 'Dos')
      kpi1.save

      kpi2 = FactoryGirl.build(:kpi, company: company, kpi_type: 'percentage', name: 'Other KPI')
      seg21 = kpi2.kpis_segments.build(text: 'Uno')
      seg22 = kpi2.kpis_segments.build(text: 'Dos')
      kpi2.save

      campaign1 = FactoryGirl.create(:campaign, company: company)
      campaign2 = FactoryGirl.create(:campaign, company: company)

      expect {
        campaign1.add_kpi(kpi1)
        campaign2.add_kpi(kpi2)
      }.to change(FormField, :count).by(2)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company: company)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company: company)
      expect {
        result = event1.result_for_kpi(kpi1)
        result.value = {seg11.id => '33', seg12.id => '67'}
        event1.save

        result = event2.result_for_kpi(kpi2)
        result.value = {seg21.id => '44', seg22.id => '56'}
        event2.save
      }.to change(FormFieldResult, :count).by(2)

      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-1)
      }.to_not change(FormFieldResult, :count)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      event1.result_for_kpi(kpi1).value.keys.should =~ [seg11.id.to_s, seg12.id.to_s]
      event1.result_for_kpi(kpi1).value.values.should == ['33', '67']

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      event2.result_for_kpi(kpi1).value.keys.should =~ [seg11.id.to_s, seg12.id.to_s]
      event2.result_for_kpi(kpi1).value.values.should == ['44', '56']
    end

    it "should allow custom kpis with a global kpi" do
      Kpi.create_global_kpis
      kpi1 = FactoryGirl.create(:kpi)
      kpi2 = FactoryGirl.create(:kpi)
      campaign1 = FactoryGirl.create(:campaign, company: company)
      campaign2 = FactoryGirl.create(:campaign, company: company)

      campaign1.assign_all_global_kpis

      expect {
        campaign1.add_kpi(kpi1)
        campaign2.add_kpi(kpi2)
      }.to change(FormField, :count).by(2)

      # Enter results for both Kpis for a event
      event1 = FactoryGirl.create(:event, campaign: campaign1, company: company)
      event2 = FactoryGirl.create(:event, campaign: campaign2, company: company)
      expect {
        result = event1.result_for_kpi(kpi1)
        result.value = 100
        event1.save

        result2 = event2.result_for_kpi(kpi2)
        result2.value = 200
        event2.save
      }.to change(FormFieldResult, :count).by(2)


      expect{
        expect{
          Kpi.where(id: [kpi1.id, kpi2.id, Kpi.impressions.id]).merge_fields({
            'name' => 'New Name',
            'description' => 'a description',
            'master_kpi' => {campaign1.id.to_s => kpi1.id, campaign2.id.to_s => kpi2.id}
          })
        }.to change(Kpi, :count).by(-2)
      }.to_not change(FormFieldResult, :count)

      event1 = Event.find(event1.id) # Load a fresh copy of the event
      result = event1.result_for_kpi(Kpi.impressions)
      result.reload
      result.value.should == '100'

      event2 = Event.find(event2.id) # Load a fresh copy of the event
      result = event2.result_for_kpi(Kpi.impressions)
      result.reload
      result.value.should == '200'
    end
  end
end