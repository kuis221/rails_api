require 'rails_helper'

describe 'TrendObject' do
  let(:campaign) { create(:campaign) }
  let(:comment) { create(:comment, commentable: event) }
  let(:activity ) { create(:activity, activity_type: activity_type,
        activitable: event, campaign: campaign, company_user_id: 1) }
  let(:activity_type) { create(:activity_type, company: campaign.company) }
  let(:field) { create(:form_field, type: 'FormField::TextArea', fieldable: activity_type ) }
  let(:event) { create(:event, campaign: campaign, company: campaign.company) }
  let(:campaign) { create(:campaign) }

  it "should return the correct id" do
    trend = TrendObject.new(comment)
    expect(trend.id).to eql "comment:#{comment.id}"
    expect(trend.resource).to eql comment
  end

  describe "load_objects" do
    it "loads the correct comment based on given id" do
      expect(TrendObject.load_objects(["comment:#{comment.id}"]).map(&:resource)).to match_array [comment]
    end

    it "loads the correct form results based on given id" do
      result = create(:form_field_result, form_field: field, resultable: event)
      expect(TrendObject.load_objects(["form_field_result:#{result.id}"]).map(&:result)).to match_array [result]
    end
  end

  describe "do_search", search: true do
    before { campaign.activity_types << activity_type }

    it "loads the correct objects" do
      comment.id

      activity.results_for([field]).first.value = 'this have a value'
      expect { activity.save }.to change(FormFieldResult, :count).by(1)

      Sunspot.commit

      response = TrendObject.do_search(company_id: comment.company_id)
      expect(response.results.count).to eql 2
      expect(response.results.map(&:resource)).to match_array [comment, activity]

      response = TrendObject.do_search(company_id: comment.company_id, source: 'Comment')
      expect(response.results.count).to eql 1
      expect(response.results.map(&:resource)).to match_array [comment]

      response = TrendObject.do_search(
        company_id: comment.company_id,
        source: 'ActivityType:' + activity_type.id.to_s)
      expect(response.results.count).to eql 1
      expect(response.results.map(&:resource)).to match_array [activity]

      response = TrendObject.do_search(
        company_id: comment.company_id,
        question:  field.id)
      expect(response.results.count).to eql 1
      expect(response.results.map(&:resource)).to match_array [activity]
    end
  end

  describe 'solr_index', search: true do
    before { campaign.activity_types << activity_type }

    it 'works' do
      event_field = create(:form_field_text, fieldable: campaign)

      event.results_for([event_field]).first.value = 'this have a value'
      event.save

      comment.save

      activity.results_for([field]).first.value = 'this have a value'
      activity.save

      TrendObject.reindex
      Sunspot.commit

      search = TrendObject.do_search(company_id: campaign.company_id)
      expect(search.results.map(&:resource)).to match_array [activity, comment, event]
    end
  end
end