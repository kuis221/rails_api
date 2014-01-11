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

  protected

    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(survey: [:content])[:comment]
    end
end