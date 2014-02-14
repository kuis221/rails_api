class Api::V1::SurveysController < Api::V1::ApiController

  inherit_resources

  belongs_to :event

  resource_description do
    short 'Surveys'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/events/:event_id/surveys', "Get a list of surveys for an Event"
  param :event_id, :number, required: true, desc: "Event ID"
  description <<-EOS
    Returns a list of surveys associated to the event.

    The results are sorted ascending by +id+.

    Each item have the following attributes:
    * *id*: the comment id
    * *active*: boolean indicating if the survey is active or not
    * *updated_at*: the comment text
    * *created_at*: the date and time of creation for the comment
    * *survey_answers*:
      * *id*:  the answer id
      * *question_id*: the ID of the questions this answer applies to (if any)
      * *kpi_id*: the ID of the KPI this answer applies to (if any)
      * *brand_id*: the ID of the brand that this answer applies to (if any)
      * *answer*: the user's answer for the question
  EOS
  example <<-EOS
    GET: /api/v1/events/1351/surveys.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
        {
            "id": 1,
            "active": true,
            "created_at": "2013-11-11T12:08:23-08:00",
            "updated_at": "2013-11-11T12:08:23-08:00",
            "surveys_answers": [
                {
                    "id": 1,
                    "kpi_id": 6,
                    "question_id": 1,
                    "brand_id": null,
                    "answer": "9"
                },
                {
                    "id": 2,
                    "kpi_id": 7,
                    "question_id": 1,
                    "brand_id": null,
                    "answer": "4"
                },
                {
                    "id": 3,
                    "kpi_id": 8,
                    "question_id": 1,
                    "brand_id": null,
                    "answer": "13"
                },
                {
                    "id": 13,
                    "kpi_id": null,
                    "question_id": 1,
                    "brand_id": 2,
                    "answer": "purchased"
                },
                {
                    "id": 14,
                    "kpi_id": null,
                    "question_id": 1,
                    "brand_id": 5,
                    "answer": "aware"
                },
                {
                    "id": 15,
                    "kpi_id": null,
                    "question_id": 1,
                    "brand_id": 7,
                    "answer": "purchased"
                },
                {
                    "id": 16,
                    "kpi_id": null,
                    "question_id": 2,
                    "brand_id": 2,
                    "answer": "100"
                },
                {
                    "id": 17,
                    "kpi_id": null,
                    "question_id": 2,
                    "brand_id": 5,
                    "answer": ""
                },
                {
                    "id": 18,
                    "kpi_id": null,
                    "question_id": 2,
                    "brand_id": 7,
                    "answer": "23"
                },
                {
                    "id": 19,
                    "kpi_id": null,
                    "question_id": 3,
                    "brand_id": 2,
                    "answer": "2"
                },
                {
                    "id": 20,
                    "kpi_id": null,
                    "question_id": 3,
                    "brand_id": 5,
                    "answer": "4"
                },
                {
                    "id": 21,
                    "kpi_id": null,
                    "question_id": 3,
                    "brand_id": 7,
                    "answer": "3"
                },
                {
                    "id": 22,
                    "kpi_id": null,
                    "question_id": 4,
                    "brand_id": 2,
                    "answer": "3"
                },
                {
                    "id": 23,
                    "kpi_id": null,
                    "question_id": 4,
                    "brand_id": 5,
                    "answer": "5"
                },
                {
                    "id": 24,
                    "kpi_id": null,
                    "question_id": 4,
                    "brand_id": 7,
                    "answer": "6"
                }
            ]
        }
    ]
  EOS
  def index
    @surveys = parent.surveys
  end


  api :POST, '/api/v1/events/:event_id/surveys', 'Create a new survey for a event'
  param :survey, Hash, required: true, :action_aware => true do
    param :surveys_answers_attributes, Hash, required: true do
      param :kpi_id, [6,7,8], desc: 'The kpi_id of this answer. "6" for gender, "7" for age or "8" for ethnicity. (if this is an answer that is related to a kpi.)'
      param :brand_id, :number, desc: 'The ID of the brand for this answer, if this is an answer that is related to a brand.'
      param :question_id, [1,2,3,4], desc: 'The number of the question for this answer.'
      param :answer, String, desc: <<-EOS
      The value for this answer. Depending of what is this for, the value can be one of the following:

      For the Age KPI:
      * *1*: < 12
      * *2*: 12 – 17
      * *387*: 18 – 20
      * *3*: 21 – 24
      * *4*: 25 – 34
      * *5*: 35 – 44
      * *6*: 45 – 54
      * *7*: 55 – 64
      * *8*: 65+


      For the ethnicity KPI:
      * *11*: Asian
      * *12*: Black / African American
      * *13*: Hispanic / Latino
      * *14*: Native American
      * *15*: White

      For the gender KPI:
      * *9*: Female
      * *10*: Male

      For Question #1:
      Can be any of: ["purchased", "aware", "unaware"]

      For Question #2:
      Can be any of: [1, 2, 3, 4, 5]

      For Question #3:
      Can be any of: [1, 2, 3, 4, 5]
      EOS
    end
  end
  description <<-EOS
  An answer have to have a one of the following convinations:
  * kpi_id and answer
  * brand_id, question_id and answer
  EOS
  example <<-EOS
  POST /api/v1/events/1322/surveys
  DATA:
  "survey": {
    "surveys_answers_attributes": [
      {"kpi_id"=> 6, "answer"=> 9},
      {"kpi_id"=> 7, "answer"=> 387},
      {"kpi_id"=> 8, "answer"=> },
      {"brand_id"=>brand1.to_param, "question_id"=>"1", "answer"=>"aware"},
      {"brand_id"=>brand2.to_param, "question_id"=>"1", "answer"=>"aware"},
      {"brand_id"=>brand1.to_param, "question_id"=>"2", "answer"=>"4"},
      {"brand_id"=>brand2.to_param, "question_id"=>"2", "answer"=>"5"},
      {"brand_id"=>brand1.to_param, "question_id"=>"3", "answer"=>"2"},
      {"brand_id"=>brand2.to_param, "question_id"=>"3", "answer"=>"2"},
      {"brand_id"=>brand1.to_param, "question_id"=>"4", "answer"=>"3"},
      {"brand_id"=>brand2.to_param, "question_id"=>"4", "answer"=>"4"}
    ]
  }

  RESPONSE:
  {
     "id":1,
     "active":true,
     "created_at":"2014-01-13T15:19:30-08:00",
     "updated_at":"2014-01-13T15:19:30-08:00",
     "surveys_answers":[
        {
           "id":1,
           "kpi_id":6,
           "question_id":null,
           "brand_id":null,
           "answer":"10"
        },
        {
           "id":2,
           "kpi_id":7,
           "question_id":null,
           "brand_id":null,
           "answer":"5"
        },
        {
           "id":3,
           "kpi_id":8,
           "question_id":null,
           "brand_id":null,
           "answer":"11"
        },
        {
           "id":4,
           "kpi_id":null,
           "question_id":1,
           "brand_id":1,
           "answer":"aware"
        },
        {
           "id":5,
           "kpi_id":null,
           "question_id":1,
           "brand_id":2,
           "answer":"aware"
        },
        {
           "id":6,
           "kpi_id":null,
           "question_id":2,
           "brand_id":1,
           "answer":""
        },
        {
           "id":7,
           "kpi_id":null,
           "question_id":2,
           "brand_id":2,
           "answer":""
        },
        {
           "id":8,
           "kpi_id":null,
           "question_id":3,
           "brand_id":1,
           "answer":"2"
        },
        {
           "id":9,
           "kpi_id":null,
           "question_id":3,
           "brand_id":2,
           "answer":"2"
        },
        {
           "id":10,
           "kpi_id":null,
           "question_id":4,
           "brand_id":1,
           "answer":"3"
        },
        {
           "id":11,
           "kpi_id":null,
           "question_id":4,
           "brand_id":2,
           "answer":"4"
        }
     ]
  }
  EOS
  def create
    create! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  protected

    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(survey: {surveys_answers_attributes: [:id, :brand_id, :question_id, :answer, :kpi_id]})[:survey]
    end
end