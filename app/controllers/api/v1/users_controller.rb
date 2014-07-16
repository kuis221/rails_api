class Api::V1::UsersController < Api::V1::FilteredController
  include UsersHelper

  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  skip_authorization_check only: [:new_password, :companies, :permissions, :notifications]

  defaults resource_class: CompanyUser

  def_param_group :user do
    param :company_user, Hash, required: true, :action_aware => true do
      param :user_attributes, Hash, required: true, :action_aware => true do
        param :first_name, String, required: true, desc: "User's first name"
        param :last_name, String, required: true, desc: "User's last name"
        param :email, String, required: true, desc: "User's email address"
        param :phone_number, String, required: true, desc: "User's phone number"
        param :password, String, required: false, desc: "User's password"
        param :password_confirmation, String, required: false, desc: "User's password confirmation"
        param :street_address, String, required: true, desc: "User's street address 1"
        param :unit_number, String, required: false, desc: "User's street address 2"
        param :country, String, required: true, desc: "User's country code, eg: US, UK, AR"
        param :state, String, required: true, desc: "User's state code, eg: CA, TX"
        param :city, String, required: true, desc: "User's city"
        param :zip_code, String, required: true, desc: "User's ZIP code"
        param :time_zone, String, required: true, desc: "User's time zone"
        param :id, :number, required: true, desc: "User ID"
      end
    end
  end

  resource_description do
    short 'Users'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    description <<-EOS

    EOS
  end

  api :POST, '/api/v1/users/password/new_password', 'Request a new password for a user'
  param :email, String, required: true, desc: "User's email"
  def new_password
    resource = User.send_reset_password_instructions(params)

    if resource.persisted?
      render :status => 200,
             :json => { :success => true,
                        :info => "Reset password instructions sent",
                        :data => {} }
    else
      failure
    end
  end

  api :GET, '/api/v1/users', "Get a list of users for a specific company"
  param :auth_token, String, required: true
  param :company_id, :number, required: true
  param :campaign, Array, :desc => "A list of campaign ids. If given, the list will include only users that are assigned to these campaigns"
  param :team, Array, :desc => "A list of team ids. If given, the list will include only users that are members of these teams"
  param :role, Array, :desc => "A list of role ids. If given, the list will include only users with there roles"
  description <<-EOS
    Returns a full list of the existing users in the company. Only active users are returned.
    Each user have the following attributes:
    * *id*: the user id
    * *first_name*: the user's first name
    * *last_name*: the user's last name
    * *full_name*: the user's full name
    * *role_name*: the user's role name
    * *email*: the user's email address
    * *street_address*: the user's street name and number
    * *city*: the user's city name
    * *state*: the user's state code
    * *zip_code*: the user's ZIP code
    * *time_zone*: the user's time zone
    * *country*: the user's country
  EOS
  example <<-EOS
    A list of users for company id 1:
    GET /api/v1/users?auth_token=XXXXXYYYYYZZZZZ&company_id=1
    [
        {
            "id": 268,
            "first_name": "Trinity",
            "last_name": "Ruiz",
            "full_name": "Trinity Ruiz",
            "role_name": "MBN Supervisor",
            "email": "trinity.ruiz@gmail.com",
            "phone_number": "+1 233 245 4332",
            "street_address": "1st Young st.,",
            "city": "Toronto",
            "state": "ON",
            "zip_code": "54783",
            "time_zone"=>"Pacific Time (US & Canada)",
            "country": "Canada"
        }
    ]
  EOS

  example <<-EOS
    A list of ACTIVE users for company id 1 filtered by roles 1 and 2:
    GET /api/v1/users?auth_token=XXXXXYYYYYZZZZZ&company_id=1&role[]=1&role[]=2
    [
        {
            "id": 268,
            "first_name": "Trinity",
            "last_name": "Ruiz",
            "full_name": "Trinity Ruiz",
            "role_name": "MBN Supervisor",
            "email": "trinity.ruiz@gmail.com",
            "phone_number": "+1 233 245 4332",
            "street_address": "1st Young st.,",
            "city": "Toronto",
            "state": "ON",
            "zip_code": "54783",
            "time_zone"=>"Pacific Time (US & Canada)",
            "country": "Canada"
        }
    ]
  EOS
  def index
    if current_user.present?
      collection
    else
      failure
    end
  end


  api :GET, '/api/v1/users/:id', 'Return a user\'s details'
  param :id, :number, required: true, desc: "User ID"
  description <<-EOS
    Returns the details of a give user
      * *id*: the user id
      * *first_name*: the user's first name
      * *last_name*: the user's last name
      * *full_name*: the user's full name
      * *email*: the user's email address
      * *street_address*: the user's street name and number
      * *city*: the user's city name
      * *state*: the user's state code
      * *country*: the user's country
      * *zip_code*: the user's ZIP code
      * *role*:
        * *id*: the role id
        * *name*: the role name
      * *teams*: A list of the teams that the user belongs to
        * *id*: the team's id
        * *name*: the team's name
  EOS
  example <<-EOS
  {
      "id": 1,
      "first_name": "Admin",
      "last_name": "User",
      "full_name": "Admin User",
      "email": "admin@brandscopic.com",
      "phone_number": null,
      "street_address": null,
      "unit_number": null,
      "city": "San Francisco",
      "state": "CA",
      "zip_code": null,
      "time_zone": "Buenos Aires",
      "country": "United States",
      "role": {
          "id": 1,
          "name": "Super Admin"
      },
      "teams": []
  }
  EOS
  def show
    if resource.present?
      render
    end
  end

  api :PUT, '/api/v1/users/:id', 'Update a user\'s details'
  param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
  param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
  param :id, :number, required: true, desc: "Company User ID"
  param_group :user
  param :team_ids, Array, required: false, desc: "Teams that the user belongs"
  param :role_id, :number, required: false, desc: "User's role ID"
  description <<-EOS
  Updates the user's data and returns all the user's updated info.
  EOS
  example <<-EOS
    PUT /api/v1/users/140?auth_token=XXXXXYYYYYZZZZZ&company_id=1
    DATA:
    {
        company_user: {
            user_attributes: {
                "first_name"=>"Trinity",
                "last_name"=>"Blue",
                "email"=>"trinity@matrix.com",
                "phone_number"=>"+1 233 245 4332",
                "password"=>"Pass12345",
                "password_confirmation"=>"Pass12345",
                "street_address"=>"1120 N Street",
                "unit_number"=>"Room #101",
                "country"=>"US",
                "city"=>"Beberly Hills",
                "state"=>"CA",
                "zip_code"=>"90210",
                "time_zone"=>"Pacific Time (US & Canada)",
                "id"=>"136"
            },
            "team_ids"=>["19", "20"],
            "role_id"=>"21"
        }
    }

    RESPONSE:
    {
        "id": 140,
        "first_name": "Trinity",
        "last_name": "Blue",
        "full_name": "Trinity Blue",
        "email": "trinity@matrix.com",
        "phone_number": "+1 233 245 4332",
        "street_address": "1120 N Street",
        "unit_number": "Room #101",
        "city": "Beberly Hills",
        "state": "CA",
        "zip_code": "90210",
        "time_zone"=>"Pacific Time (US & Canada)",
        "country": "United States",
        "role": {
            "id": 21,
            "name": "My Custom Role"
        },
        "teams": [
            {
                "id": 19,
                "name": "Team #1"
            },
            {
                "id": 20,
                "name": "Team #2"
            }
        ]
    }
  EOS
  def update
    update! do |success, failure|
      success.json { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
    end
  end

  api :GET, '/api/v1/companies', "Get a list of companies the user has access to"
  param :auth_token, String, required: true
  example <<-EOS
    GET /api/v1/companies?auth_token=XXXXXYYYYYZZZZZ

    [
        {
            "name": "Brandscopic",
            "id": 1
        },
        {
            "name": "Legacy Marketing Partners",
            "id": 2
        }
    ]
  EOS
  def companies
    if current_user.present?
      companies = current_user.companies_active_role.map{|c| {name: c.name, id: c.id} }
      respond_to do |format|
        format.json {
          render :status => 200,
                 :json => companies
        }
        format.xml {
          render :status => 200,
                 :xml => companies.to_xml(root: 'companies')
        }
      end
    else
      failure
    end
  end

  api :GET, '/api/v1/users/notifications', "Get a list of user's notifications"
  param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
  param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"

  description <<-EOS
  Returns a list of notifications for the current user with the following atttibutes:

  * *message*: A human readable description of the notification.
  * *level*: Indicates the level of the notification. Possible options are: "red", "grey" and "blue"
  * *icon*: An string that could be used to identify what icon to use for the notification
  * *type*: The type of notification, the possible options are:
    * *event_recaps_due*: At least one event is due
    * *event_recaps_late*: At least one event is late
    * *event_recaps_pending*: There is at least one event that is waiting for approval
    * *event_recaps_rejected*: There is at least one event that was rejected
    * *team_tasks_late*: The user's team have late tasks
    * *user_tasks_late*: The user have late tasks
    * *user_task_comments*: One or more user's team tasks have a commment
    * *team_task_comments*: One or more user tasks have a commment
    * *new_event*: The user have been assigned to a event
    * *new_campaign*: The user have been assigned to a campaign
    * *new_team_task*: The user's team have been assigned to a task
    * *new_task*: The user have been assigned to a task
  * *event_id*: when the notification is about a single event, this indicates the event's ID
  * *campaign_id*: when the notification is about a single campaign, this indicates the campaign's ID
  * *task_id*: when the notification is about a single task, this indicates the task's ID

  EOS

  example <<-EOS
  GET /api/v1/users/notifications.json?auth_token=XXXXXYYYYYZZZZZ&company_id=1
  [
      {
          "message": "There is one late event recap",
          "level": "red",
          "icon": "icon-notification-event",
          "type": "event_recaps_late"
      },
      {
          "message": "You have one late task",
          "level": "red",
          "icon": "icon-notification-task",
          "type": "user_tasks_late"
      },
      {
          "message": "You have a new event",
          "level": "grey",
          "icon": "icon-notification-event",
          "type": "new_event",
          "event_id": 5262
      },
      {
          "message": "You have a new campaign",
          "level": "grey",
          "icon": "icon-notification-campaign",
          "type": "new_campaign",
          "campaign_id": 31
      },
      {
          "message": "You have been assigned a task: Pick up t-shirts",
          "level": "grey",
          "icon": "icon-notification-task",
          "type": "new_task",
          "task_id": 187
      }
  ]
  EOS
  def notifications
    if current_user.present?
      notifications = notifications_for_company_user(current_company_user).map{|n| n.delete(:url); n.delete(:unread); n }

      companies = current_user.companies_active_role.map{|c| {name: c.name, id: c.id} }
      respond_to do |format|
        format.json {
          render :status => 200,
                 :json => notifications
        }
        format.xml {
          render :status => 200,
                 :xml => notifications.to_xml(root: 'notifications')
        }
      end
    else
      failure
    end
  end


  api :GET, '/api/v1/users/permissions', "Get a list of the user's permissions"
  param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
  param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
  example <<-EOS
    GET /api/v1/users/permissions.json?auth_token=XXXXXYYYYYZZZZZ&company_id=1

    ['events', 'events_create', 'venues', 'tasks']
  EOS

  description <<-EOS
  Returns a list of the user's permissions on a given company. A user can have different permissions
  each company.

  This is the list of the available permissions:

  * _events_: Can access the events list page
  * _events_create_: Can create events
  * _events_show_: Can access the event details page
  * _events_edit_: Can edit a event
  * _events_deactivate_: Can deactivate a event
  * _events_team_members_: Can see event's the team members
  * _events_add_team_members_: Can add existing users to a event as part of the event team
  * _events_delete_team_members_: Can delete members from the event's team
  * _events_contacts_: Can see the list of contacts for the event
  * _events_delete_contacts_: Can delete contacts
  * _events_edit_contacts_: Can edit contacts
  * _events_add_contacts_: Can add existing contacts to a event
  * _events_documents_: Can see the list of documents associated to a event
  * _events_create_documents_: Can create documents.
  * _events_deactivate_documents_: Can deactivate documents
  * _events_expenses_: Can see the list of event's expenses
  * _events_deactivate_expenses_: Can deactivate expenses
  * _events_edit_expenses_: Can edit expenses
  * _events_create_expenses_: Can create expenses
  * _events_photos_: Can see the photos associated to a event
  * _events_create_photos_: Can add photos to a event
  * _events_deactivate_photos_: Can deactivate photos
  * _events_surveys_: Can see the list of surveys of a event
  * _events_create_surveys_: Can create surveys
  * _events_edit_surveys_: Can edit surveys
  * _events_deactivate_surveys_: Can deactivate surveys
  * _events_create_tasks_: Can create tasks for a event
  * _events_edit_tasks_: Can edit the tasks of a event
  * _events_tasks_: Can see a list of tasks for a event
  * _tasks_own_: Can see his own tasks
  * _tasks_team_: Can see his team's taks
  * _tasks_comments_own_: Can see the comments on tasks assigned to him
  * _tasks_create_comments_own_: Can create comments on tasks assigned to him
  * _tasks_comments_team_: Can see the comments on his team's tasks
  * _tasks_create_comments_team_: Can create comments on the user team's tasks
  * _tasks_deactivate_own_: Can deactivate his own tasks
  * _tasks_deactivate_team_: Can deactivate his team's tasks
  * _tasks_edit_own_: Can edit his own tasks
  * _tasks_edit_team_: Can edit his team's tasks
  * _venues_: Can see the list of venues
  * _venues_create_: Can create venues
  EOS
  def permissions
    if current_user.present?
      respond_to do |format|
        format.json {
          render :status => 200,
                 :json => user_permissions
        }
        format.xml {
          render :status => 200,
                 :xml => user_permissions.to_xml(root: 'permissions')
        }
      end
    else
      failure
    end
  end

  def failure
    render :status => 401,
           :json => { :success => false,
                      :info => "Action Failed",
                      :data => {} }
  end

  private
    def permitted_params
      allowed = {company_user: [{user_attributes: [:id, :first_name, :last_name, :email, :phone_number, :password, :password_confirmation, :country, :state, :city, :street_address, :unit_number, :zip_code, :time_zone]}] }
      if params[:id].present? && can?(:super_update, CompanyUser.find(params[:id]))
        allowed[:company_user] += [:role_id, {team_ids: []}]
      end
      params.permit(allowed)[:company_user]
    end

    def search_params
      super
      @search_params[:status] = ['Active']
      @search_params
    end

    def permitted_search_params
      params.permit({role: []}, {status: []}, {team: []}, {campaign: []})
    end

    def user_permissions
      permissions = []
      permissions.push 'events' if can?(:view_list, Event)
      permissions.push 'events_create' if can?(:create, Event)
      permissions.push 'events_show' if current_company_user.role.has_permission?(:show, Event)
      permissions.push 'events_edit' if can?(:update, Event)
      permissions.push 'events_deactivate' if can?(:deactivate, Event)
      permissions.push 'events_team_members' if current_company_user.role.has_permission?(:view_members, Event)
      permissions.push 'events_add_team_members' if current_company_user.role.has_permission?(:add_members, Event)
      permissions.push 'events_delete_team_members' if current_company_user.role.has_permission?(:delete_member, Event)
      permissions.push 'events_contacts' if current_company_user.role.has_permission?(:view_contacts, Event)
      permissions.push 'events_add_contacts' if current_company_user.role.has_permission?(:create_contacts, Event)
      permissions.push 'events_edit_contacts' if current_company_user.role.has_permission?(:edit_contacts, Event)
      permissions.push 'events_delete_contacts' if current_company_user.role.has_permission?(:delete_contact, Event)
      permissions.push 'events_tasks' if can?(:index_tasks, Event)
      permissions.push 'events_create_tasks' if can?(:create_task, Event)
      permissions.push 'events_edit_tasks' if can?(:edit_task, Event)
      permissions.push 'events_documents' if can?(:index_documents, Event)
      permissions.push 'events_create_documents' if can?(:create_document, Event)
      permissions.push 'events_deactivate_documents' if can?(:deactivate_document, Event)
      permissions.push 'events_photos' if can?(:index_photos, Event)
      permissions.push 'events_create_photos' if can?(:create_photo, Event)
      permissions.push 'events_deactivate_photos' if can?(:deactivate_photo, Event)
      permissions.push 'events_expenses' if can?(:index_expenses, Event)
      permissions.push 'events_create_expenses' if can?(:create_expense, Event)
      permissions.push 'events_edit_expenses' if can?(:edit_expense, Event)
      permissions.push 'events_deactivate_expenses' if can?(:deactivate_expense, Event)
      permissions.push 'events_surveys' if can?(:index_surveys, Event)
      permissions.push 'events_create_surveys' if can?(:create_survey, Event)
      permissions.push 'events_edit_surveys' if can?(:edit_survey, Event)
      permissions.push 'events_deactivate_surveys' if can?(:deactivate_survey, Event)
      permissions.push 'events_comments' if can?(:index_comments, Event)
      permissions.push 'events_create_comments' if can?(:create_comment, Event)
      permissions.push 'events_edit_comments' if can?(:edit_comment, Event)
      permissions.push 'events_deactivate_comments' if can?(:deactivate_comment, Event)

      permissions.push 'venues' if can?(:index, Venue)
      permissions.push 'venues_create' if can?(:create, Venue)

      permissions.push 'tasks_own' if can?(:index_my, Task)
      permissions.push 'tasks_edit_own' if can?(:edit_my, Task)
      permissions.push 'tasks_deactivate_own' if can?(:edit_my, Task)
      permissions.push 'tasks_comments_own' if can?(:index_my_comments, Task)
      permissions.push 'tasks_create_comments_own' if can?(:create_my_comment, Task)

      permissions.push 'tasks_team' if can?(:index_team, Task)
      permissions.push 'tasks_edit_team' if can?(:edit_team, Task)
      permissions.push 'tasks_deactivate_team' if can?(:edit_team, Task)
      permissions.push 'tasks_comments_team' if can?(:index_team_comments, Task)
      permissions.push 'tasks_create_comments_team' if can?(:create_team_comment, Task)

      permissions
    end

end