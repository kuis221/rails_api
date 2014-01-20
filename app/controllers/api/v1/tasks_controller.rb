class Api::V1::TasksController < Api::V1::FilteredController

  include TasksFacetsHelper

  belongs_to :event, optional: true

  resource_description do
    short 'Tasks'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true
    param :company_id, :number, required: true
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/events/:event_id/tasks', "Get a list of taks for an Event"
  api :GET, '/api/v1/tasks/teams', "Get a list of taks for the user's teams"
  api :GET, '/api/v1/tasks/mine', "Get a list of taks for the user"
  param :event_id, :number, required: false, desc: "Event ID, required when getting the list of tasks for a event"
  param :status, Array, :desc => "A list of photo status to filter the results. Options: Active, Inactive"
  param :task_status, Array, :desc => "A list of photo status to filter the results. Options: Late, Complete, Incomplete, Assigned, Unassigned"
  param :page, :number, :desc => "The number of the page, Default: 1"
  example <<-EOS
    Get a list of active tasks
    GET /api/v1/events/4924/tasks.json?auth_token=ehWs_NZ2Uq5-39tGzWpZ&company_id=2&status[]=Active
    {
        "page": 1,
        "total": 1,
        "facets": [
            {
                "label": "Campaigns",
                "items": [
                    {
                        "label": "Kahlua Midnight FY14",
                        "id": 33,
                        "name": "campaign",
                        "selected": false
                    }
                ]
            },
            {
                "label": "Task Status",
                "items": [
                    {
                        "label": "Complete",
                        "id": "Complete",
                        "name": "task_status",
                        "count": 0,
                        "selected": false
                    },
                    {
                        "label": "Incomplete",
                        "id": "Incomplete",
                        "name": "task_status",
                        "count": 4,
                        "selected": false
                    },
                    {
                        "label": "Late",
                        "id": "Late",
                        "name": "task_status",
                        "count": 2,
                        "selected": false
                    },
                    {
                        "label": "Assigned",
                        "id": "Assigned",
                        "name": "task_status",
                        "count": 3,
                        "selected": false
                    },
                    {
                        "label": "Unassigned",
                        "id": "Unassigned",
                        "name": "task_status",
                        "count": 1,
                        "selected": false
                    }
                ]
            },
            {
                "label": "Active State",
                "items": [
                    {
                        "label": "Active",
                        "id": "Active",
                        "name": "status",
                        "count": 3,
                        "selected": false
                    },
                    {
                        "label": "Inactive",
                        "id": "Inactive",
                        "name": "status",
                        "count": 1,
                        "selected": true
                    }
                ]
            }
        ],
        "results": [
            {
                "id": 30,
                "title": "Inactive task",
                "due_at": null,
                "completed": false,
                "active": false,
                "status": [
                    "Inactive",
                    "Assigned",
                    "Incomplete"
                ],
                "user": {
                    "id": 7,
                    "full_name": "Guillermo Vargas"
                }
            }
        ]
    }
  EOS
  def index
    collection
  end

  api :GET, '/api/v1/tasks/:id/comments', "Get a list of comments for a Task"
  param :id, :number, required: true, desc: "Task ID"
  description <<-EOS
    Returns a list of comments associated to a given task.

    The results are sorted ascending by +created_at+.

    Each item have the following attributes:
    * *id*: the comment id
    * *name*: the comment text
    * *created_at*: the date and time of creation for the comment
    * *created_by:* information of the creator of the comment

       This will contain a list with the following attributes:

       * *id:* the user ID for the comment creator
       * *full_name:* the name for the comment creator
  EOS
  example <<-EOS
    An example with comments for an event in the response
    GET: /api/v1/tasks/353/comments.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
      {
        "id": 10,
        "content": "Comment #1 - Task 353",
        "created_at": "2013-10-03T08:42:32-07:00",
        "created_by": {
          "id": 2,
          "full_name": "Test User"
        }
      },
      {
        "id": 11,
        "content": "Comment #2 - Task 353",
        "created_at": "2013-10-03T08:42:38-07:00",
        "created_by": {
          "id": 2,
          "full_name": "Test User"
        }
      }
    ]
  EOS
  def comments
    @comments = resource.comments
  end

  protected

    def permitted_search_params
      params.permit(:event_id, {status: []}, {task_status: []})
    end

    def search_params
      super
      @search_params.merge!(Task.search_params_for_scope(params[:scope], current_company_user))
    end
end