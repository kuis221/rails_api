# == Schema Information
#
# Table name: event_results
#
#  id              :integer          not null, primary key
#  form_field_id   :integer
#  event_id        :integer
#  kpis_segment_id :integer
#  value           :text
#  scalar_value    :decimal(10, 2)   default(0.0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  kpi_id          :integer
#

require 'spec_helper'

describe EventResult do
  before { subject.form_field = CampaignFormField.new(field_type: 'number') }

  it { should belong_to(:event) }
  it { should belong_to(:kpis_segment) }
  it { should belong_to(:form_field) }


  it { should validate_presence_of(:form_field_id) }
  it { should validate_numericality_of(:form_field_id) }

  describe "for integer fields" do
    before { subject.form_field = CampaignFormField.new({field_type: 'number', options: {capture_mechanism: 'integer'}}, without_protection: true) }
    it { should validate_numericality_of(:value) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
    it { should_not allow_value(12.23).for(:value) }
  end

  describe "for decimal fields" do
    before { subject.form_field = CampaignFormField.new({field_type: 'number', options: {capture_mechanism: 'decimal'}}, without_protection: true) }
    it { should validate_numericality_of(:value) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
    it { should allow_value(12.23).for(:value) }
    it { should allow_value(0.23).for(:value) }
  end

  describe "for currency fields" do
    before { subject.form_field = CampaignFormField.new({field_type: 'number', options: {capture_mechanism: 'currency'}}, without_protection: true) }
    it { should validate_numericality_of(:value) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
    it { should allow_value(12.23).for(:value) }
    it { should allow_value(0.23).for(:value) }
  end

  describe "for non numeric fields" do
    before { subject.form_field = CampaignFormField.new(field_type: 'text') }
    it { should_not validate_numericality_of(:value) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
  end

  describe "for count/radio fields" do
    before do
      @segment = FactoryGirl.create(:kpis_segment, kpi: FactoryGirl.create(:kpi, kpi_type: 'count'))
      subject.form_field = FactoryGirl.create(:campaign_form_field, field_type: 'count', options: {capture_mechanism: 'radio'}, kpi: @segment.kpi)
      @segment.kpi.reload
    end
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
    it { should allow_value(@segment.id).for(:value) }
    it { should_not allow_value(987654).for(:value).with_message('is not valid') }
  end

  describe "for count/checkboxes fields" do
    before do
      @kpi = FactoryGirl.create(:kpi, kpi_type: 'count')
      @segments = FactoryGirl.create_list(:kpis_segment, 3, kpi: @kpi)
      subject.form_field = FactoryGirl.create(:campaign_form_field, field_type: 'count', options: {capture_mechanism: 'checkbox'}, kpi: @kpi)
      @kpi.reload
    end
    it { should allow_value(nil).for(:value) }
    it { should allow_value(@segments.map(&:id).join(',')).for(:value) }
    it { should allow_value(@segments.first.id).for(:value) }
    it { should_not allow_value(889889).for(:value).with_message('is not valid') }
    it { should_not allow_value('666666').for(:value).with_message('is not valid') }
    it { should_not allow_value(['abc']).for(:value).with_message('is not valid') }
    it { should_not allow_value([1]).for(:value).with_message('is not valid') }
  end

  describe "display_value" do
    describe "for count/check fields" do
      before do
        @segment = FactoryGirl.create(:kpis_segment, text: 'The text here', kpi: FactoryGirl.create(:kpi, kpi_type: 'count'))
        @form_field = FactoryGirl.create(:campaign_form_field, field_type: 'count', kpi_id: @segment.kpi.id, options: {:capture_mechanism => 'radio'})
      end
      it "should return the segment's text" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: @segment.id)
        result.display_value.should == 'The text here'
      end
      it "should return nil if the value is nil" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: nil)
        result.display_value.should be_nil
      end
    end

    describe "for count/checkbox fields" do
      before do
        @kpi = FactoryGirl.create(:kpi, kpi_type: 'count')
        @segments = [FactoryGirl.create(:kpis_segment, text: 'One option', kpi: @kpi),
                     FactoryGirl.create(:kpis_segment, text: 'Another option', kpi: @kpi)]
        @form_field = FactoryGirl.create(:campaign_form_field, field_type: 'count', kpi_id: @kpi.id, options: {:capture_mechanism => 'checkbox'})
      end

      it "should return the segment's text" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: @segments.first.id.to_s)
        result.display_value.should == 'One option'
      end

      it "should return the segments texts separated by a comma" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: @segments.map(&:id).join(','))
        result.display_value.should == 'One option and Another option'
      end

      it "should return nil if the value is nil" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: nil)
        result.display_value.should be_nil
      end
    end


    describe "for number/integer fields" do
      before do
        @kpi = FactoryGirl.create(:kpi, kpi_type: 'number')
        @form_field = FactoryGirl.create(:campaign_form_field, field_type: 'number', kpi_id: @kpi.id, options: {:capture_mechanism => 'integer'})
      end

      it "should return the value as a number" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: '100')
        result.display_value.should == 100
      end

      it "should return the value as an integer" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: '10.3')
        result.display_value.should == 10
      end

      it "should return the value as an integer" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: '10.3')
        result.display_value.should == 10
      end

      it "should return nil if the value is nil" do
        result = FactoryGirl.build(:event_result, form_field: @form_field, value: nil)
        result.display_value.should be_nil
      end
    end
  end

end
