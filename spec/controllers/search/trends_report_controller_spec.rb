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

end