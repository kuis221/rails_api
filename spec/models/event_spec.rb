# == Schema Information
#
# Table name: events
#
#  id            :integer          not null, primary key
#  campaign_id   :integer
#  company_id    :integer
#  start_at      :datetime
#  end_at        :datetime
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active        :boolean          default(TRUE)
#

require 'spec_helper'

describe Event do
  it { should belong_to(:campaign) }
  it { should have_and_belong_to_many(:users) }
  it { should have_many(:tasks) }

  it { should allow_mass_assignment_of(:end_date) }
  it { should allow_mass_assignment_of(:end_time) }
  it { should allow_mass_assignment_of(:start_date) }
  it { should allow_mass_assignment_of(:start_time) }
  it { should allow_mass_assignment_of(:campaign_id) }
  it { should allow_mass_assignment_of(:event_ids) }
  it { should allow_mass_assignment_of(:user_ids) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:aasm_state) }
  it { should_not allow_mass_assignment_of(:active) }
  it { should_not allow_mass_assignment_of(:created_by_id) }
  it { should_not allow_mass_assignment_of(:updated_by_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  it { should validate_presence_of(:campaign_id) }
  it { should validate_numericality_of(:campaign_id) }
  it { should validate_presence_of(:start_at) }
  it { should validate_presence_of(:end_at) }

  describe "end_after_start validation" do
    subject { Event.new({start_at: DateTime.new(2016,1,20,12,5,0)}, without_protection: true) }

    it { should_not allow_value(DateTime.new(2016,1,20,12,0,0)).for(:end_at).with_message("must be after the start time.") }
    it { should allow_value(DateTime.new(2016,1,20,12,5,0)).for(:end_at) }
    it { should allow_value(DateTime.new(2016,1,20,12,10,0)).for(:end_at) }
  end

  describe "#start_at attribute" do
    it "should be correcly set when assigning valid start_date and start_time" do
      event = Event.new
      event.start_date = '01/20/2012'
      event.start_time = '12:05pm'
      event.valid?
      event.start_at.should == DateTime.new(2012,1,20,12,5,0)
    end

    it "should be nil if no start_date and start_time are provided" do
      event = Event.new
      event.valid?
      event.start_at.should be_nil
    end

    it "should have only the date if no start_time provided" do
      event = Event.new
      event.start_date = '01/20/2012'
      event.start_time = nil
      event.valid?
      event.start_at.should == DateTime.new(2012,1,20,0,0,0)
    end
  end

  describe "#end_at attribute" do
    it "should be correcly set when assigning valid end_date and end_time" do
      event = Event.new
      event.end_date = '01/20/2012'
      event.end_time = '12:05pm'
      event.valid?
      event.end_at.should == DateTime.new(2012,1,20,12,5,0)
    end

    it "should be nil if no end_date and end_time are provided" do
      event = Event.new
      event.valid?
      event.end_at.should be_nil
    end

    it "should have only the date if no end_time provided" do
      event = Event.new
      event.end_date = '01/20/2012'
      event.end_time = nil
      event.valid?
      event.end_at.should == DateTime.new(2012,1,20,0,0,0)
    end

  end
end
