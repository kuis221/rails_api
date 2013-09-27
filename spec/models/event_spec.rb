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
#  place_id      :integer
#  promo_hours   :decimal(6, 2)    default(0.0)
#  reject_reason :text
#  summary       :text
#

require 'spec_helper'

describe Event do
  it { should belong_to(:company) }
  it { should belong_to(:campaign) }
  it { should have_many(:memberships) }
  it { should have_many(:users).through(:memberships) }
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

  describe "event results validations" do
    it "should not allow submitting the event if the resuls are not valid" do
      campaign = FactoryGirl.create(:campaign, company_id: 1)
      field = FactoryGirl.create(:campaign_form_field, campaign: campaign, kpi: FactoryGirl.create(:kpi, company_id: 1), field_type: 'number', options: {required: true})
      event = FactoryGirl.create(:event, campaign: campaign, company_id: 1)

      expect {
        event.submit
      }.to raise_exception(AASM::InvalidTransition)

      event.results_for([field]).each {|r| r.value = 100}
      event.save
      event.submit.should be_true
    end
  end

  describe "states" do
    before(:each) do
      @event = FactoryGirl.create(:event)
    end

    describe ":unsent" do
      it 'should be an initial state' do
        @event.should be_unsent
      end

      it 'should change to :submitted on :unsent or :rejected' do
        @event.submit
        @event.should be_submitted
      end

      it 'should change to :approved on :submitted' do
        @event.submit
        @event.approve
        @event.should be_approved
      end

      it 'should change to :rejected on :submitted' do
        @event.submit
        @event.reject
        @event.should be_rejected
      end
    end
  end

  describe "end_after_start validation" do
    subject { Event.new({start_at: Time.zone.local(2016,1,20,12,5,0)}, without_protection: true) }

    it { should_not allow_value(Time.zone.local(2016,1,20,12,0,0)).for(:end_at).with_message("must be after") }
    it { should allow_value(Time.zone.local(2016,1,20,12,5,0)).for(:end_at) }
    it { should allow_value(Time.zone.local(2016,1,20,12,10,0)).for(:end_at) }
  end

  describe "#start_at attribute" do
    it "should be correctly set when assigning valid start_date and start_time" do
      event = Event.new
      event.start_date = '01/20/2012'
      event.start_time = '12:05pm'
      event.valid?
      event.start_at.should == Time.zone.local(2012,1,20,12,5,0)
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
      event.start_at.should == Time.zone.local(2012,1,20,0,0,0)
    end
  end

  describe "#end_at attribute" do
    it "should be correcly set when assigning valid end_date and end_time" do
      event = Event.new
      event.end_date = '01/20/2012'
      event.end_time = '12:05pm'
      event.valid?
      event.end_at.should == Time.zone.local(2012,1,20,12,5,0)
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
      event.end_at.should == Time.zone.local(2012,1,20,0,0,0)
    end

  end

  describe "campaign association" do
    let(:campaign) { FactoryGirl.create(:campaign) }

    it "should update campaign's first_event_id and first_event_at attributes" do
      campaign.update_attributes({first_event_id: 999, first_event_at: '2013-02-01 12:00:00'}, without_protection: true).should be_true
      event = FactoryGirl.create(:event, campaign: campaign, start_date: '01/01/2013', start_time: '01:00 AM', end_date:  '01/01/2013', end_time: '05:00 AM')
      campaign.reload
      campaign.first_event_id.should == event.id
      campaign.first_event_at.should == Time.zone.parse('2013-01-01 01:00:00')
    end

    it "should update campaign's first_event_id and first_event_at attributes" do
      campaign.update_attributes({last_event_id: 999, last_event_at: '2013-01-01 12:00:00'}, without_protection: true).should be_true
      event = FactoryGirl.create(:event, campaign: campaign, start_date: '02/01/2013', start_time: '01:00 AM', end_date:  '02/01/2013', end_time: '05:00 AM')
      campaign.reload
      campaign.last_event_id.should == event.id
      campaign.last_event_at.should == Time.zone.parse('2013-02-01 01:00:00')
    end
  end

  describe "#kpi_goals" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:event) { FactoryGirl.create(:event, campaign: campaign) }

    it "should not fail if there are not goals nor KPIs for the campaign" do
      event.kpi_goals.should == {}
    end

    it "should not fail if there are KPIs associated to the campaign but without goals" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      event.kpi_goals.should == {}
    end

    it "should not fail if the goal values are nil" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      goals = campaign.goals.for_kpis([Kpi.impressions])
      goals.each{|g| g.value = nil; g.save}
      event.kpi_goals.should == {}
    end

    it "returns the correct value for the goal" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      goals = campaign.goals.for_kpis([Kpi.impressions])
      goals.each{|g| g.value = 100; g.save}
      event.kpi_goals.should == {Kpi.impressions.id => 100}
    end

    it "returns the correctly divide the goal between the number of events" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      #Create another event for the campaign
      FactoryGirl.create(:event, campaign: campaign)
      goals = campaign.goals.for_kpis([Kpi.impressions])
      goals.each{|g| g.value = 100; g.save}
      event.kpi_goals.should == {Kpi.impressions.id => 50}
    end

  end

  describe "before_save #set_promo_hours" do
    it "correctly calculates the number of promo hours before saving the event" do
      event = FactoryGirl.build(:event,  start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/21/2020', end_time: '05:00pm')
      event.promo_hours = nil
      event.save.should be_true
      event.reload.promo_hours.should == 5
    end
    it "accepts promo_hours hours with decimals" do
      event = FactoryGirl.build(:event,  start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/21/2020', end_time: '03:15pm')
      event.promo_hours = nil
      event.save.should be_true
      event.reload.promo_hours.should == 3.25
    end
  end


  describe "in_past?" do
    it "should return true if the event is scheduled to happen in the past" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.build(:event)
        event.end_at = Time.zone.local(2013, 07, 26, 12, 00)
        event.in_past?.should be_true

        event.end_at = Time.zone.local(2013, 07, 26, 12, 12)
        event.in_past?.should be_true

        event.end_at = Time.zone.local(2013, 07, 26, 12, 15)
        event.in_past?.should be_false
      end
    end

    it "should return true if the event is scheduled to happen in the future" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.build(:event)
        event.start_at = Time.zone.local(2013, 07, 26, 12, 00)
        event.in_future?.should be_false

        event.start_at = Time.zone.local(2013, 07, 26, 12, 12)
        event.in_future?.should be_false

        event.start_at = Time.zone.local(2013, 07, 26, 12, 15)
        event.in_future?.should be_true

        event.start_at = Time.zone.local(2014, 07, 26, 12, 15)
        event.in_future?.should be_true
      end
    end
  end


  describe "is_late?" do
    it "should return true if the event is scheduled to happen in more than to days go" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/23/2013', end_date: '07/23/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.is_late?.should be_true

        event = FactoryGirl.create(:event, start_date: '01/23/2013', end_date: '01/23/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.is_late?.should be_true
      end
    end
    it "should return false if the event is end_date is less than two days ago" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/23/2013', end_date: '07/25/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.is_late?.should be_false
      end
    end
  end

  describe "happens_today?" do
    it "should return true if the current day is between the start and end dates of the event" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/26/2013', end_date: '07/26/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_true

        event = FactoryGirl.create(:event, start_date: '07/26/2013', end_date: '07/28/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_true

        event = FactoryGirl.create(:event, start_date: '07/24/2013', end_date: '07/26/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_true

        event = FactoryGirl.create(:event, start_date: '07/23/2013', end_date: '07/28/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_true
      end
    end

    it "should return true if the current day is NOT between the start and end dates of the event" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/27/2013', end_date: '07/28/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_false

        event = FactoryGirl.create(:event, start_date: '07/24/2013', end_date: '07/25/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_false
      end
    end
  end

  describe "was_yesterday?" do
    it "should return true if the end_date is the day before" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/24/2013', end_date: '07/25/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_true

        event = FactoryGirl.create(:event, start_date: '07/21/2013', end_date: '07/25/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_true

      end
    end

    it "should return false if the event's end_date is other than yesterday" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/26/2013', end_date: '07/26/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_false

        event = FactoryGirl.create(:event, start_date: '07/25/2013', end_date: '07/26/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_false


        event = FactoryGirl.create(:event, start_date: '07/24/2013', end_date: '07/24/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_false
      end
    end
  end

  describe "venue reindexing" do
    before do
      ResqueSpec.reset!
    end
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:event)    { FactoryGirl.create(:event, campaign: campaign) }

    it "should queue a job to update venue details after a event have been updated if the event data have changed" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      event.place_id = 1
      event.save # Make sure the event have a place_id
      ResqueSpec.reset!
      expect {
        field = campaign.form_fields.detect{|f| f.kpi_id == Kpi.impressions.id}
        event.update_attributes({results_attributes: {"1" => {form_field_id: field.id, kpi_id: field.kpi_id, value: '100' }}})
      }.to change(EventResult, :count).by(1)
      VenueIndexer.should have_queued(event.venue.id)
    end

    it "should queue a job to update venue details after a event have been updated if place_id changed" do
      expect {
        event.place_id =  1199
        event.save
      }.to change(Venue, :count).by(1)
      VenueIndexer.should have_queued(event.venue.id)
    end

    it "should not queue a job to reindex the venue if the place_id nor the event data have changed" do
      event.reload
      event.start_at = event.start_at - 1.hour
      event.save
      VenueIndexer.should_not have_queued(event.venue.id)
    end
  end


  describe "photos reindexing" do
    before do
      ResqueSpec.reset!
    end
    let(:event) { FactoryGirl.create(:event) }


    it "should queue a job to reindex photos after a event have been updated if place_id changed" do
      event.place_id = 1
      event.save
      ResqueSpec.reset!

      # Changing the place should reindex all photos for the event
      event.place_id =  1199
      event.save.should be_true
      EventPhotosIndexer.should have_queued(event.id)
    end

    it "should not queue a job to reindex if the place_id not changed" do
      event.place_id = 1
      event.save
      ResqueSpec.reset!

      # Changing the place should reindex all photos for the event
      event.start_at = event.start_at - 1.hour
      event.save.should be_true
      EventPhotosIndexer.should_not have_queued(event.id)
    end
  end

  describe "place_reference=" do
    it "should not fail if nill" do
      event = FactoryGirl.build(:event, place: nil)
      event.place_reference = nil
      event.place.should be_nil
    end

    it "should initialized a new place object" do
      event = FactoryGirl.build(:event, place: nil)
      event.place_reference = 'some_reference||some_id'
      event.place.should_not be_nil
      event.place.new_record?.should be_true
      event.place.place_id.should == 'some_id'
      event.place.reference.should == 'some_reference'
    end


    it "should initialized the place object" do
      place = FactoryGirl.create(:place)
      event = FactoryGirl.build(:event, place: nil)
      event.place_reference = "#{place.reference}||#{place.place_id}"
      event.place.should_not be_nil
      event.place.new_record?.should be_false
      event.place.should == place
    end
  end


  describe "demographics_graph_data" do
    let(:event) { FactoryGirl.create(:event, company_id: 1, campaign: FactoryGirl.create(:campaign, company_id: 1)) }
    it "should return the correct results" do
      Kpi.create_global_kpis
      event.campaign.assign_all_global_kpis
      set_event_results(event,
        gender_male: 35,
        gender_female: 65,
        ethnicity_asian: 15,
        ethnicity_native_american: 23,
        ethnicity_black: 24,
        ethnicity_hispanic: 26,
        ethnicity_white: 12,
        age_12: 1,
        age_12_17: 2,
        age_18_24: 4,
        age_25_34: 8,
        age_35_44: 16,
        age_45_54: 32,
        age_55_64: 24,
        age_65: 13
      )

      event.demographics_graph_data[:gender].should    == {'Female' => 65, 'Male' => 35}
      event.demographics_graph_data[:age].should       == {"< 12"=>1, "12 – 17"=>2, "18 – 24"=>4, "25 – 34"=>8, "35 – 44"=>16, "45 – 54"=>32, "55 – 64"=>24, "65+"=>13}
      event.demographics_graph_data[:ethnicity].should == {"Asian"=>15.0, "Black / African American"=>24.0, "Hispanic / Latino"=>26.0, "Native American"=>23.0, "White"=>12.0}
    end
  end


  describe "survey_statistics" do
    pending "Add tests for this method"
  end

  describe "after_remove_member" do
    let(:event) {FactoryGirl.create(:event, company_id: 1)}
    it "should be called after removign a user from the event" do
      user = FactoryGirl.create(:company_user, company_id: 1)
      event.users << user
      event.should_receive(:after_remove_member).with(user)
      event.users.delete(user)
    end

    it "should be called after removign a team from the event" do
      team = FactoryGirl.create(:team, company_id: 1)
      event.teams << team
      event.should_receive(:after_remove_member).with(team)
      event.teams.delete(team)
    end

    it "should reindex all the tasks of the event" do
      user = FactoryGirl.create(:company_user, company_id: 1)
      other_user = FactoryGirl.create(:company_user, company_id: 1)
      event.users << user
      event.users << other_user

      tasks = FactoryGirl.create_list(:task, 3, event: event)
      tasks[1].update_attribute(:company_user_id, other_user.id)
      tasks[2].update_attribute(:company_user_id, user.id)

      tasks[2].reload.company_user_id.should == user.id

      Sunspot.should_receive(:index) do |taks_list|
        taks_list.should be_an_instance_of(Array)
        taks_list.should =~ tasks
      end

      event.users.delete(user)

      tasks[1].reload.company_user_id.should == other_user.id  # This shouldn't be unassigned
      tasks[2].reload.company_user_id.should be_nil
    end

    it "should unassign all the tasks assigned to any user of the team" do
      team_user1 = FactoryGirl.create(:company_user, company_id: 1)
      team_user2 = FactoryGirl.create(:company_user, company_id: 1)
      other_user = FactoryGirl.create(:company_user, company_id: 1)
      team = FactoryGirl.create(:team, company_id: 1)
      team.users << [team_user1, team_user2]
      event.teams << team
      event.users << team_user2

      tasks = FactoryGirl.create_list(:task, 3, event: event)
      tasks[0].update_attribute(:company_user_id, other_user.id)
      tasks[1].update_attribute(:company_user_id, team_user1.id)
      tasks[2].update_attribute(:company_user_id, team_user2.id)

      tasks[1].reload.company_user_id.should == team_user1.id
      tasks[2].reload.company_user_id.should == team_user2.id

      Sunspot.should_receive(:index) do |taks_list|
        taks_list.should be_an_instance_of(Array)
        taks_list.should =~ tasks
      end

      event.teams.delete(team)

      tasks[0].reload.company_user_id.should == other_user.id  # This shouldn't be unassigned
      tasks[1].reload.company_user_id.should be_nil
      tasks[2].reload.company_user_id.should == team_user2.id  # This shouldn't be unassigned either as the user is directly assigned to the event
    end
  end

  describe "reindex_associated" do
    it "should update the campaign first and last event dates " do
      campaign = FactoryGirl.create(:campaign, company_id: 1, first_event_id: nil, last_event_at: nil, first_event_at: nil, last_event_at: nil)
      event = FactoryGirl.build(:event, company_id: 1, campaign: campaign, start_date: '01/23/2019', end_date: '01/25/2019')
      campaign.should_receive(:first_event=).with(event)
      campaign.should_receive(:last_event=).with(event)
      event.save
    end


    it "should update only the first event" do
      campaign = FactoryGirl.create(:campaign, company_id: 1, first_event_at: Time.zone.local(2013, 07, 26, 12, 13), last_event_at: Time.zone.local(2013, 07, 29, 14, 13))
      event = FactoryGirl.build(:event, company_id: 1, campaign: campaign, start_date: '07/24/2013', end_date: '07/24/2013')
      campaign.should_receive(:first_event=).with(event)
      campaign.should_not_receive(:last_event=)
      event.save
    end

    it "should update only the last event" do
      campaign = FactoryGirl.create(:campaign, company_id: 1, first_event_at: Time.zone.local(2013, 07, 26, 12, 13), last_event_at: Time.zone.local(2013, 07, 29, 14, 13))
      event = FactoryGirl.build(:event, company_id: 1, campaign: campaign, start_date: '07/30/2013', end_date: '07/30/2013')
      campaign.should_not_receive(:first_event=)
      campaign.should_receive(:last_event=).with(event)
      event.save
    end

    it "should create a new event data for the event" do
      Kpi.create_global_kpis
      campaign = FactoryGirl.create(:campaign, company_id: 1)
      campaign.assign_all_global_kpis
      event = FactoryGirl.create(:event, company_id: 1, campaign: campaign)
      expect{
        set_event_results(event,
          impressions: 100,
          interactions: 101,
          samples: 102
        )
      }.to change(EventData, :count).by(1)
      data = EventData.last
      data.impressions.should == 100
      data.interactions.should == 101
      data.samples.should == 102
    end
  end

  describe "#activate" do
    let(:event) { FactoryGirl.create(:event, active: false) }

    it "should return the active value as true" do
      event.activate!
      event.reload
      event.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:event) { FactoryGirl.create(:event, active: false) }

    it "should return the active value as false" do
      event.deactivate!
      event.reload
      event.active.should be_false
    end
  end


  describe "#result_for_kpi" do
    let(:campaign) { FactoryGirl.create(:campaign, company_id: 1) }
    let(:event) { FactoryGirl.create(:event, campaign: campaign, company_id: 1) }
    it "should return a new instance of EventResult if the event has not results for the given kpi" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      result = event.result_for_kpi(Kpi.impressions)
      result.should be_an_instance_of(EventResult)
      result.new_record?.should be_true

      # Make sure the result is correctly initialized
      result.kpi_id == Kpi.impressions.id
      result.form_field_id.should_not be_nil
      result.value.should be_nil
      result.scalar_value.should == 0
    end
  end


  describe "#results_for_kpis" do
    let(:campaign) { FactoryGirl.create(:campaign, company_id: 1) }
    let(:event) { FactoryGirl.create(:event, campaign: campaign, company_id: 1) }
    it "should return a new instance of EventResult if the event has not results for the given kpi" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      results = event.results_for_kpis([Kpi.impressions, Kpi.interactions])
      results.count.should == 2
      results.each do |result|
        result.should be_an_instance_of(EventResult)
        result.new_record?.should be_true

        # Make sure the result is correctly initialized
        [Kpi.impressions.id, Kpi.interactions.id].should include(result.kpi_id)
        result.form_field_id.should_not be_nil
        result.value.should be_nil
        result.scalar_value.should == 0
      end
    end
  end
end
