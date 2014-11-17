require 'rails_helper'

describe Analysis::TrendsController, search: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.current_company }
  let(:company_user) { user.current_company_user }
  let(:campaign) { create(:campaign, company: company) }
  let(:event) do
    create(:event, campaign: campaign,
                   start_date: Time.current.to_s(:slashes),
                   end_date: Time.current.to_s(:slashes))
  end

  before { user } # Create and Login user

  describe 'GET #items' do
    it 'returns empty if no words' do
      Sunspot.commit
      get 'items', format: :json
      items = JSON.parse(response.body)
      expect(items).to be_empty
    end

    it 'returns a list of items with the correct counting' do
      create(:comment, commentable: event, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola', 'count' => 1, 'current' => 1,
          'previous' => 0, 'trending' => 'up' }
      ]
    end

    it 'returns trending down if the word count decreased in the current period' do
      event = create(:event, campaign: campaign,
                             start_date: 3.weeks.ago.to_s(:slashes),
                             end_date: 3.weeks.ago.to_s(:slashes))
      create(:comment, commentable: event, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola', 'count' => 1, 'current' => 0,
          'previous' => 1, 'trending' => 'down' }
      ]
    end

    it 'returns trending stable if the word count is the same as the previous period' do
      create(:comment, commentable: event, content: 'hola')

      event2 = create(:event, campaign: campaign,
                              start_date: 3.weeks.ago.to_s(:slashes),
                              end_date: 3.weeks.ago.to_s(:slashes))
      create(:comment, commentable: event2, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola', 'count' => 2, 'current' => 1,
          'previous' => 1, 'trending' => 'stable' }
      ]
    end

    it 'returns trending stable if the word count is between 10% down of the previous period' do
      create_list(:comment, 10, commentable: event, content: 'hola')

      event2 = create(:event, campaign: campaign,
                              start_date: 3.weeks.ago.to_s(:slashes),
                              end_date: 3.weeks.ago.to_s(:slashes))
      create_list(:comment, 9, commentable: event2, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola', 'count' => 19, 'current' => 10,
          'previous' => 9, 'trending' => 'stable' }
      ]
    end

    it 'returns trending stable if the word count is between 10% up of the previous period' do
      create_list(:comment, 10, commentable: event, content: 'hola')

      event2 = create(:event, campaign: campaign,
                              start_date: 3.weeks.ago.to_s(:slashes),
                              end_date: 3.weeks.ago.to_s(:slashes))
      create_list(:comment, 11, commentable: event2, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola', 'count' => 21, 'current' => 10,
          'previous' => 11, 'trending' => 'stable' }
      ]
    end

    it 'returns trending down if the word count is lower than 10% of the previous period' do
      create_list(:comment, 10, commentable: event, content: 'hola')

      event2 = create(:event, campaign: campaign,
                              start_date: 3.weeks.ago.to_s(:slashes),
                              end_date: 3.weeks.ago.to_s(:slashes))
      create_list(:comment, 12, commentable: event2, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola', 'count' => 22, 'current' => 10,
          'previous' => 12, 'trending' => 'down' }
      ]
    end

    it 'returns trending up if the word count is greater than 10% of the previous period' do
      create_list(:comment, 10, commentable: event, content: 'hola')

      event2 = create(:event, campaign: campaign,
                              start_date: 3.weeks.ago.to_s(:slashes),
                              end_date: 3.weeks.ago.to_s(:slashes))
      create_list(:comment, 8, commentable: event2, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola', 'count' => 18, 'current' => 10,
          'previous' => 8, 'trending' => 'up' }
      ]
    end

    it 'returns trending up if the word count increased from the previous period' do
      create(:comment, commentable: event, content: 'hola')
      create(:comment, commentable: event, content: 'hola')

      event2 = create(:event, campaign: campaign,
                              start_date: 3.weeks.ago.to_s(:slashes),
                              end_date: 3.weeks.ago.to_s(:slashes))
      create(:comment, commentable: event2, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola',  'count' => 3, 'current' => 2,
          'previous' => 1, 'trending' => 'up' }
      ]
    end

    it 'returns stable if the word doesn\'t appear in any of the periods' do
      event = create(:event, campaign: campaign,
                             start_date: 3.years.ago.to_s(:slashes),
                             end_date: 3.years.ago.to_s(:slashes))
      create(:comment, commentable: event, content: 'hola')
      Sunspot.commit

      get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'hola', 'count' => 1, 'current' => 0,
          'previous' => 0, 'trending' => 'stable' }
      ]
    end

    describe 'filters' do
      it 'correctly returns the words for comments' do
        create(:comment, commentable: event, content: 'hola')
        Sunspot.commit

        get 'items', campaign: [campaign.id], source: ['Comment'], format: :json

        items = JSON.parse(response.body)

        expect(items.count).to eql 1
      end

      it 'ignores the words for comments' do
        create(:comment, commentable: event, content: 'hola')
        Sunspot.commit

        get 'items', campaign: [campaign.id], source: ['ActivityType:1'], format: :json
        items = JSON.parse(response.body)

        expect(items).to be_empty
      end

      it 'only includes the words for the date range' do
        create(:comment, commentable: event, content: 'hola')
        create(:comment, commentable: event, content: 'hola')

        event2 = create(:event, campaign: campaign,
                                start_date: 3.weeks.ago.to_s(:slashes),
                                end_date: 3.weeks.ago.to_s(:slashes))
        create(:comment, commentable: event2, content: 'otra')
        create(:comment, commentable: event2, content: 'hola')

        Sunspot.commit

        get 'items', campaign: [campaign.id], source: ['Comment'],
                     format: :json,
                     start_date: 2.days.ago.to_s(:slashes),
                     end_date: Date.tomorrow.to_s(:slashes)

        items = JSON.parse(response.body)

        expect(items).to match_array [
          { 'name' => 'hola', 'count' => 2, 'current' => 2,
            'previous' => 1, 'trending' => 'up' }
        ]
      end

      it 'returns empty there are no words on the given range' do
        create(:comment, commentable: event, content: 'hola')
        create(:comment, commentable: event, content: 'hola')

        event2 = create(:event, campaign: campaign,
                                start_date: 3.weeks.ago.to_s(:slashes),
                                end_date: 3.weeks.ago.to_s(:slashes))
        create(:comment, commentable: event2, content: 'otra')
        create(:comment, commentable: event2, content: 'hola')

        Sunspot.commit

        get 'items', campaign: [campaign.id], source: ['Comment'],
                     format: :json,
                     start_date: 5.days.ago.to_s(:slashes),
                     end_date: 2.days.ago.to_s(:slashes)

        items = JSON.parse(response.body)

        expect(items).to be_empty
      end
    end
  end

  describe 'GET #over_time' do
    it 'returns empty if no results' do
      create(:comment, commentable: event, content: 'hola')
      create(:comment, commentable: event, content: 'hola')

      Sunspot.commit
      get 'mentions_over_time', campaign: [campaign.id], source: ['Comment'],
                                term: 'adios', format: :json

      items = JSON.parse(response.body)

      expect(items).to be_empty
    end

    it 'returns the count for each day the word appears' do
      Time.use_zone(user.time_zone) do
        activity_type = create(:activity_type, company: company)
        form_field = FormField.find(
          create(:form_field_text_area, fieldable: activity_type).id
        )
        campaign.activity_types << activity_type

        create(:comment, commentable: event, content: 'hola')
        create(:comment, commentable: event, content: 'hola')
        create(:comment, commentable: event, content: 'holas') # this should not be counted

        yesterday = (Time.current - 1.day).to_s(:slashes)
        event2 = create(:event, campaign: campaign,
                                start_date: yesterday,
                                end_date: yesterday)
        create(:comment, commentable: event2, content: 'otra')
        create(:comment, commentable: event2, content: 'hola')

        activity = create(:activity, activity_type: activity_type,
          activitable: event2, activity_date: yesterday,
          company_user: company_user)

        activity.results_for([form_field]).first.value = 'Texto con hola en medio!'
        activity.save

        Sunspot.commit

        get 'mentions_over_time', campaign: [campaign.id],
                                  source: ['Comment', "ActivityType:#{activity_type.id}"],
                                  question: [form_field.id],
                                  term: 'hola', format: :json

        items = JSON.parse(response.body)

        expect(items.count).to eql 2
        expect(DateTime.strptime(items.first[0].to_s, '%Q').to_date).to eql (Time.current - 1.day).to_date
        expect(items.first[1]).to eql 2
        expect(DateTime.strptime(items.last[0].to_s, '%Q').to_date).to eql Time.current.to_date
        expect(items.last[1]).to eql 2
      end
    end

    it 'should fill in missing days with zeros' do
      create(:comment, commentable: event, content: 'hola')
      create(:comment, commentable: event, content: 'hola')

      event2 = create(:event, campaign: campaign,
                              start_date: 3.days.ago.to_s(:slashes),
                              end_date: 3.days.ago.to_s(:slashes))
      create(:comment, commentable: event2, content: 'hola')

      Sunspot.commit

      get 'mentions_over_time', campaign: [campaign.id], source: ['Comment'],
                                term: 'hola', format: :json

      items = JSON.parse(response.body)

      expect(items.map { |i| i[1] }).to eql [1, 0, 0, 2]
    end
  end

  describe 'GET #items' do
    it 'returns empty if no words' do
      Sunspot.commit
      get 'search', term: 'abs', format: :json
      items = JSON.parse(response.body)
      expect(items).to be_empty
    end

    it 'returns a list of items with the correct counting' do
      create(:comment, commentable: event, content: 'absolute')
      create(:comment, commentable: event, content: 'other')
      Sunspot.commit

      get 'search', campaign: [campaign.id], source: ['Comment'],
                    term: 'abs', format: :json

      items = JSON.parse(response.body)

      expect(items).to match_array [
        { 'name' => 'absolute', 'count' => 1, 'current' => 1,
          'previous' => 0, 'trending' => 'up' }
      ]
    end
  end

end
