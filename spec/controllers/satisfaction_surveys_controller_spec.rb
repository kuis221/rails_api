require 'spec_helper'

describe SatisfactionSurveysController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "POST create" do
    let(:satisfaction_survey){ FactoryGirl.create(:satisfaction_survey, company_user: @company_user, session_id: request.session_options[:id], feedback: '') }

    it "should create a new satisfaction survey" do
      expect {
        post 'create', rating: 'neutral', feedback: 'This is my feeling', format: :js
      }.to change(SatisfactionSurvey, :count).by(1)
      response.should be_success
      satisfaction = SatisfactionSurvey.last
      satisfaction.company_user_id.should == @company_user.id
      satisfaction.rating.should == 'neutral'
      satisfaction.feedback.should == 'This is my feeling'
    end

    it "should not create a new satisfaction survey" do
      expect {
        post 'create', format: :js
      }.to_not change(SatisfactionSurvey, :count)
    end

    it "must update the satisfaction survey attributes" do
      put 'create', record_id: satisfaction_survey.to_param, feedback: 'Nice app. Excellent job!'
      satisfaction_survey.reload
      satisfaction_survey.company_user_id.should == @company_user.id
      satisfaction_survey.rating.should == 'positive'
      satisfaction_survey.feedback.should == 'Nice app. Excellent job!'
    end
  end
end
