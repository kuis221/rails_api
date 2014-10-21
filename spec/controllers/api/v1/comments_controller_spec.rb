require 'rails_helper'

describe Api::V1::CommentsController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
  let(:place) { create(:place) }

  before { set_api_authentication_headers user, company }

  describe "GET 'index'" do
    it 'returns the list of comments for the event' do
      event = create(:approved_event, company: company, campaign: campaign, place: place)
      comment1 = create(:comment, content: 'Comment #1', commentable: event, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      comment2 = create(:comment, content: 'Comment #2', commentable: event, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      event.comments << comment1
      event.comments << comment2
      event.save
      Sunspot.commit

      get :index, event_id: event.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(2)
      expect(result).to eq([{
                             'id' => comment1.id,
                             'content' => 'Comment #1',
                             'created_at' => '2013-08-22T11:59:00.000-07:00'
                           },
                            {
                              'id' => comment2.id,
                              'content' => 'Comment #2',
                              'created_at' => '2013-08-23T09:15:00.000-07:00'
                            }])
    end
  end

  describe "POST 'create'" do
    let(:event) { create(:approved_event, company: company, campaign: campaign, place: place) }
    it 'create a new comment for an existing event' do
      expect do
        post 'create', event_id: event.to_param, comment: { content: 'The very new comment' }, format: :json
      end.to change(Comment, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('show')
      comment = Comment.last
      expect(comment.content).to eq('The very new comment')
      expect(event.comments).to eq([comment])
    end
  end

  describe "PUT 'update'" do
    let(:campaign) { create(:campaign, company: company) }
    let(:event) { create(:event, company: company, campaign: campaign) }
    let(:comment) { create(:comment, commentable: event) }

    it 'must update the event attributes' do
      put 'update', id: comment.to_param, event_id: event.to_param,
                    comment: { content: 'New comment content' }, format: :json
      expect(assigns(:comment)).to eq(comment)
      expect(response).to be_success
      comment.reload
      expect(comment.content).to eq('New comment content')
    end
  end

  describe "DELETE 'destroy'" do
    let(:campaign) { create(:campaign, company: company) }
    let(:event) { create(:event, company: company, campaign: campaign) }
    let(:comment) { create(:comment, commentable: event) }

    it 'must update the event attributes' do
      comment.save
      expect do
        delete 'destroy', id: comment.to_param, event_id: event.to_param, format: :json
      end.to change(Comment, :count).by(-1)
      expect(response).to be_success
    end
  end
end
