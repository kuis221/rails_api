require 'spec_helper'

describe Analysis::TrendsReportController, search: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.current_company }
  let(:company_user) { user.current_company_user }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:event) { FactoryGirl.create(:event, campaign: campaign,
    start_date: Date.today.to_s(:slashes),
    end_date: Date.today.to_s(:slashes)) }

  before { user } # Create and Login user

  describe "GET #items" do
    it "returns empty if no words" do
      Sunspot.commit
      get 'items', format: :json
      items = JSON.parse(response.body)
      expect(items).to be_empty
    end

    it "returns a list of items with the correct counting" do
      FactoryGirl.create(:comment, commentable: event, content: 'hola')
      Sunspot.commit

      get 'items', format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        {"name"=>"hola", "count"=>1, "current"=>1, "previous"=>0, "trending"=>"up"}
      ]
    end

    it "returns trending down if the word count decreased in the current period" do
      event = FactoryGirl.create(:event, campaign: campaign,
        start_date: 3.weeks.ago.to_s(:slashes),
        end_date: 3.weeks.ago.to_s(:slashes))
      FactoryGirl.create(:comment, commentable: event, content: 'hola')
      Sunspot.commit

      get 'items', format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        {"name"=>"hola", "count"=>1, "current"=>0, "previous"=>1, "trending"=>"down"}
      ]
    end

    it "returns trending stable if the word count is the same as the previous period" do
      FactoryGirl.create(:comment, commentable: event, content: 'hola')

      event2 = FactoryGirl.create(:event, campaign: campaign,
        start_date: 3.weeks.ago.to_s(:slashes),
        end_date: 3.weeks.ago.to_s(:slashes))
      FactoryGirl.create(:comment, commentable: event2, content: 'hola')
      Sunspot.commit

      get 'items', format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        {"name"=>"hola", "count"=>2, "current"=>1, "previous"=>1, "trending"=>"stable"}
      ]
    end

    it "returns trending up if the word count increased from the previous period" do
      FactoryGirl.create(:comment, commentable: event, content: 'hola')
      FactoryGirl.create(:comment, commentable: event, content: 'hola')

      event2 = FactoryGirl.create(:event, campaign: campaign,
        start_date: 3.weeks.ago.to_s(:slashes),
        end_date: 3.weeks.ago.to_s(:slashes))
      FactoryGirl.create(:comment, commentable: event2, content: 'hola')
      Sunspot.commit

      get 'items', format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        {"name"=>"hola", "count"=>3, "current"=>2, "previous"=>1, "trending"=>"up"}
      ]
    end

    it "returns stable if the word doesn't appear in any of the periods" do
      event = FactoryGirl.create(:event, campaign: campaign,
        start_date: 3.years.ago.to_s(:slashes),
        end_date: 3.years.ago.to_s(:slashes))
      FactoryGirl.create(:comment, commentable: event, content: 'hola')
      Sunspot.commit

      get 'items', format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        {"name"=>"hola", "count"=>1, "current"=>0, "previous"=>0, "trending"=>"stable"}
      ]
    end

    describe "filters" do
      it "correctly returns the words for comments" do
        FactoryGirl.create(:comment, commentable: event, content: 'hola')
        Sunspot.commit

        get 'items', source: ['Comment'], format: :json

        items = JSON.parse(response.body)

        expect(items.count).to eql 1
      end

      it "ignores the words for comments" do
        FactoryGirl.create(:comment, commentable: event, content: 'hola')
        Sunspot.commit

        get 'items', source: ['ActivityType:1'], format: :json
        items = JSON.parse(response.body)

        expect(items).to be_empty
      end

      it "only includes the words for the date range" do
        FactoryGirl.create(:comment, commentable: event, content: 'hola')
        FactoryGirl.create(:comment, commentable: event, content: 'hola')

        event2 = FactoryGirl.create(:event, campaign: campaign,
          start_date: 3.weeks.ago.to_s(:slashes),
          end_date: 3.weeks.ago.to_s(:slashes))
        FactoryGirl.create(:comment, commentable: event2, content: 'otra')
        FactoryGirl.create(:comment, commentable: event2, content: 'hola')

        Sunspot.commit

        get 'items', format: :json,
          start_date: 2.days.ago.to_s(:slashes),
          end_date: Date.tomorrow.to_s(:slashes)

        items = JSON.parse(response.body)

        expect(items).to match_array [
          {"name"=>"hola", "count"=>2, "current"=>2, "previous"=>1, "trending"=>"up"}
        ]
      end

      it "returns empty there are no words on the given range" do
        FactoryGirl.create(:comment, commentable: event, content: 'hola')
        FactoryGirl.create(:comment, commentable: event, content: 'hola')

        event2 = FactoryGirl.create(:event, campaign: campaign,
          start_date: 3.weeks.ago.to_s(:slashes),
          end_date: 3.weeks.ago.to_s(:slashes))
        FactoryGirl.create(:comment, commentable: event2, content: 'otra')
        FactoryGirl.create(:comment, commentable: event2, content: 'hola')

        Sunspot.commit

        get 'items', format: :json,
          start_date: 5.days.ago.to_s(:slashes),
          end_date: 2.days.ago.to_s(:slashes)

        items = JSON.parse(response.body)

        expect(items).to be_empty
      end
    end
  end

  describe "GET #over_time" do
    it "returns empty if no results" do
      FactoryGirl.create(:comment, commentable: event, content: 'hola')
      FactoryGirl.create(:comment, commentable: event, content: 'hola')

      Sunspot.commit
      get 'over_time', term: 'adios', format: :json

      items = JSON.parse(response.body)

      expect(items).to be_empty
    end

    it "returns the count for each day the word appears" do
      activity_type = FactoryGirl.create(:activity_type, company: company)
      form_field = FormField.find(
        FactoryGirl.create(:form_field_text_area, fieldable: activity_type).id
      )
      campaign.activity_types << activity_type

      FactoryGirl.create(:comment, commentable: event, content: 'hola')
      FactoryGirl.create(:comment, commentable: event, content: 'hola')
      FactoryGirl.create(:comment, commentable: event, content: 'holas') # this should not be counted

      event2 = FactoryGirl.create(:event, campaign: campaign,
        start_date: Date.yesterday.to_s(:slashes),
        end_date: Date.yesterday.to_s(:slashes))
      FactoryGirl.create(:comment, commentable: event2, content: 'otra')
      FactoryGirl.create(:comment, commentable: event2, content: 'hola')

      activity = FactoryGirl.create(:activity, activity_type: activity_type,
        activitable: event2, activity_date: Date.yesterday.to_s(:slashes),
        company_user: company_user)

      activity.results_for([form_field]).first.value = 'Texto con hola en medio!'
      activity.save

      Sunspot.commit

      get 'over_time', term: 'hola', format: :json

      items = JSON.parse(response.body)

      expect(items.count).to eql 2
      expect(DateTime.strptime(items.first[0].to_s,'%Q').to_date).to eql Date.yesterday
      expect(items.first[1]).to eql 2
      expect(DateTime.strptime(items.last[0].to_s,'%Q').to_date).to eql Date.today
      expect(items.last[1]).to eql 2
    end

    it "should fill in missing days with zeros" do
      FactoryGirl.create(:comment, commentable: event, content: 'hola')
      FactoryGirl.create(:comment, commentable: event, content: 'hola')

      event2 = FactoryGirl.create(:event, campaign: campaign,
        start_date: 3.days.ago.to_s(:slashes),
        end_date: 3.days.ago.to_s(:slashes))
      FactoryGirl.create(:comment, commentable: event2, content: 'hola')

      Sunspot.commit

      get 'over_time', term: 'hola', format: :json

      items = JSON.parse(response.body)

      expect(items.count).to eql 4
      expect(items.map{|i| i[1]}).to eql [1, 0, 0, 2]
    end
  end

end