class Api::V1::CampaignsController < Api::V1::FilteredController

  skip_authorization_check :only => [:all, :overall_stats]


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

  api :GET, '/api/v1/campaigns/overall_stats', "Returns a list of categories with the results for the events and promo hours goals."
  description <<-EOS
    Returns a list of categories with the results for the events and promo hours goals.

    Each list item have the followign attributes:

    * *id*: the campaign's ID
    * *name*: the campaign's name
    * *start_date*: the campaign's start date
    * *end_date*: the campaign's end date
    * *goal*: the campaign's goal for that +kpi+
    * *kpi*: the kpi name for what the current statistics are for.
    * *executed*: indicates how many events or promo hours have been executed (approved) so far.
    * *scheduled*: indicates how many events or promo hours have been scheduled but no yet approved.
    * *remaining*: indicates how many events or promo hours are left to reach the goal
    * *executed_percentage*: indicates the percentage executed events/promo hours
    * *scheduled_percentage*: indicates the percentage scheduled events/promo hours
    * *remaining_percentage*: indicates the percentage remaining events/promo hours
    * *today*: indicates how many events or promo hours should have been executed until today
    * *today_percentage*: indicates the expected percentage of events or promo hours that should have been executed until today.
  EOS

  example <<-EOS
  GET: /api/v1/campaigns/overall_stats.json?auth_token=ehWs_NZ2Uq539tGzWpZ&company_id=1
  [
    {
        "id": 14,
        "name": "ABSOLUT BA FY14",
        "start_date": "2013-08-01",
        "end_date": "2014-06-30",
        "goal": 3368,
        "kpi": "EVENTS",
        "executed": 1063,
        "scheduled": 26,
        "remaining": 2279,
        "executed_percentage": 31,
        "scheduled_percentage": 0,
        "remaining_percentage": 69,
        "today": 2123.963963963964,
        "today_percentage": 63
    },
    {
        "id": 57,
        "name": "ABSOLUT Bloody FY14",
        "start_date": null,
        "end_date": null,
        "goal": 429,
        "kpi": "PROMO HOURS",
        "executed": 412,
        "scheduled": 17.5,
        "remaining": 0,
        "executed_percentage": 96,
        "scheduled_percentage": 4,
        "remaining_percentage": 0
    },
    {
        "id": 22,
        "name": "ABSOLUT Bloody Incremental FY14",
        "start_date": null,
        "end_date": null,
        "goal": 97,
        "kpi": "PROMO HOURS",
        "executed": 90.5,
        "scheduled": 3,
        "remaining": 3.5,
        "executed_percentage": 93,
        "scheduled_percentage": 3,
        "remaining_percentage": 4
    },
    {
        "id": 21,
        "name": "ABSOLUT Large Shaker FY14",
        "start_date": null,
        "end_date": null,
        "goal": 395,
        "kpi": "PROMO HOURS",
        "executed": 364.5,
        "scheduled": 34.5,
        "remaining": 0,
        "executed_percentage": 92,
        "scheduled_percentage": 8,
        "remaining_percentage": 0
    },
    ...
  ]
  EOS
  def overall_stats
    data = current_company.campaigns.active.accessible_by_user(current_company_user).order(:name).promo_hours_graph_data
    respond_to do |format|
        format.json {
          render :status => 200,
                 :json => data
        }
        format.xml {
          render :status => 200,
                 :xml => data.to_xml(root: 'results')
        }
    end
  end

api :GET, '/api/v1/campaigns/:id/stats', "Returns the stats of events and promo hours goals grouped by area for a given campaign."
  description <<-EOS
    Returns a list of areas with the results for the events and promo hours goals.

    Each list item have the followign attributes:

    * *id*: the areas's ID
    * *name*: the areas's name
    * *goal*: the areas's goal for that +kpi+
    * *kpi*: the kpi name for what the current statistics are for.
    * *executed*: indicates how many events or promo hours have been executed (approved) so far.
    * *scheduled*: indicates how many events or promo hours have been scheduled but no yet approved.
    * *remaining*: indicates how many events or promo hours are left to reach the goal
    * *executed_percentage*: indicates the percentage executed events/promo hours
    * *scheduled_percentage*: indicates the percentage scheduled events/promo hours
    * *remaining_percentage*: indicates the percentage remaining events/promo hours
    * *today*: indicates how many events or promo hours should have been executed until today
    * *today_percentage*: indicates the expected percentage of events or promo hours that should have been executed until today.
  EOS

  example <<-EOS
  GET: /api/v1/campaigns/1/stats.json?auth_token=ehWs_NZ2Uq539tGzWpZ&company_id=1
  [
    {
        "id": 14,
        "name": "Los Angeles",
        "goal": 3368,
        "kpi": "EVENTS",
        "executed": 1063,
        "scheduled": 26,
        "remaining": 2279,
        "executed_percentage": 31,
        "scheduled_percentage": 0,
        "remaining_percentage": 69,
        "today": 2123.963963963964,
        "today_percentage": 63
    },
    {
        "id": 57,
        "name": "Chicago",
        "goal": 429,
        "kpi": "EVENTS",
        "executed": 412,
        "scheduled": 17.5,
        "remaining": 0,
        "executed_percentage": 96,
        "scheduled_percentage": 4,
        "remaining_percentage": 0
    },
    {
        "id": 22,
        "name": "Chicago",
        "goal": 97,
        "kpi": "PROMO HOURS",
        "executed": 90.5,
        "scheduled": 3,
        "remaining": 3.5,
        "executed_percentage": 93,
        "scheduled_percentage": 3,
        "remaining_percentage": 4
    },
    {
        "id": 21,
        "name": "New York",
        "goal": 395,
        "kpi": "PROMO HOURS",
        "executed": 364.5,
        "scheduled": 34.5,
        "remaining": 0,
        "executed_percentage": 92,
        "scheduled_percentage": 8,
        "remaining_percentage": 0
    },
    ...
  ]
  EOS
  def stats
    authorize! :view_promo_hours_data, resource
    data = resource.promo_hours_graph_data
    respond_to do |format|
        format.json {
          render :status => 200,
                 :json => data
        }
        format.xml {
          render :status => 200,
                 :xml => data.to_xml(root: 'results')
        }
    end
  end
end