require 'spec_helper'

describe Api::V1::CommentsController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { FactoryGirl.create(:campaign, company: company, name: 'Test Campaign FY01') }
  let(:place) { FactoryGirl.create(:place) }

  describe "GET 'index'" do
    it "should return failure for invalid authorization token" do
      get :index, company_id: company.to_param, auth_token: 'XXXXXXXXXXXXXXXX', event_id: 100, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "returns the list of comments for the event" do
      event = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)
      comment1 = FactoryGirl.create(:comment, content: 'Comment #1', commentable: event, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      comment2 = FactoryGirl.create(:comment, content: 'Comment #2', commentable: event, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      event.comments << comment1
      event.comments << comment2
      event.save
      Sunspot.commit

      get :index, company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result.count.should == 2
      result.should == [{
                         'id' => comment1.id,
                         'content' => 'Comment #1',
                         'created_at' => '2013-08-22T11:59:00-07:00'
                        },
                        {
                         'id' => comment2.id,
                         'content' => 'Comment #2',
                         'created_at' => '2013-08-23T09:15:00-07:00'
                        }]
    end
  end

  describe "POST 'create'" do
    let(:event) {FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)}
    it "create a new comment for an existing event" do
      expect {
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, event_id: event.to_param, comment: {content: 'The very new comment'}, format: :json
      }.to change(Comment, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('show')
      comment = Comment.last
      comment.content.should == 'The very new comment'
      event.comments.should == [comment]
    end
  end

  describe "PUT 'update'" do
    let(:campaign){ FactoryGirl.create(:campaign, company: company) }
    let(:event){ FactoryGirl.create(:event, company: company, campaign: campaign) }
    let(:comment){ FactoryGirl.create(:comment, commentable: event) }

    it "must update the event attributes" do
      put 'update', auth_token: user.authentication_token, company_id: company.to_param,
                    id: comment.to_param, event_id: event.to_param,
                    comment: {content: 'New comment content' }, format: :json
      assigns(:comment).should == comment
      response.should be_success
      comment.reload
      comment.content.should == 'New comment content'
    end
  end
end