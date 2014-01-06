class Api::V1::CampaignsController < Api::V1::FilteredController
  resource_description do
    short 'Campaigns'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
  end

  api :GET, '/api/v1/campaigns/all', "Returns a list of active campaigns. Useful for generating dropdown elements"
  description <<-EOS
    Returns a list of campaigns sorted by name. Only those campaigns that are accessible for the user will be returned.

    Each campaign item have the followign attributes:

    * *id*: the campaign's ID
    * *name*: the campaign's name
  EOS

  example <<-EOS
  GET: /api/v1/campaigns/all.json?auth_token=ehWs_NZ2Uq539tGzWpZ&company_id=1
  [
      {
          "id": 14,
          "name": "ABSOLUT BA FY14"
      },
      {
          "id": 57,
          "name": "ABSOLUT Bloody FY14"
      },
      {
          "id": 22,
          "name": "ABSOLUT Bloody Incremental FY14"
      },
      ...
  ]
  EOS
  def all
    @campaigns = current_company.campaigns.active.accessible_by_user(current_company_user).order(:name)
  end
end