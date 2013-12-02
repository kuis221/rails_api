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
            name: 'New Name',
            description: 'a description',
            master_kpi: {campaigns[0].id.to_s => kpi1.id, campaigns[1].id.to_s => kpi1.id}
          })
        }.to change(CampaignFormField, :count).by(-2)
      }.to change(Kpi, :count).by(-1)

      kpi1.reload
      kpi1.name.should == 'New Name'
      kpi1.description.should == 'a description'
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
          name: 'New Name',
          description: 'a description',
          master_kpi: {campaign.id.to_s => kpi1.id}
        })
      }.to change(EventResult, :count).by(-1)

      event.reload
      result = event.result_for_kpi(kpi1)
      result.reload
      result.value.should == 100
    end
  end
end
