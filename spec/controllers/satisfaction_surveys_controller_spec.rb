require 'rails_helper'

describe SatisfactionSurveysController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "POST create" do
    let(:satisfaction_survey){ FactoryGirl.create(:satisfaction_survey,
      company_user: @company_user, session_id: request.session_options[:id], feedback: '') }

    it "should create a new satisfaction survey" do
      expect {
        xhr :post, 'create', rating: 'neutral', feedback: 'This is my feeling', format: :js
      }.to change(SatisfactionSurvey, :count).by(1)
      expect(response).to be_success
      satisfaction = SatisfactionSurvey.last
      expect(satisfaction.company_user_id).to eq(@company_user.id)
      expect(satisfaction.rating).to eq('neutral')
      expect(satisfaction.feedback).to eq('This is my feeling')
    end

    it "should not create a new satisfaction survey" do
      expect {
        xhr :post, 'create', format: :js
      }.to_not change(SatisfactionSurvey, :count)
    end

    it "must update the satisfaction survey attributes" do
      satisfaction_survey.save
      put 'create', feedback: 'Nice app. Excellent job!'
      satisfaction_survey.reload
      expect(satisfaction_survey.company_user_id).to eq(@company_user.id)
      expect(satisfaction_survey.rating).to eq('positive')
      expect(satisfaction_survey.feedback).to eq('Nice app. Excellent job!')
    end
  end
end
