class TasksController < FilteredController
  belongs_to :event, :company_user, :optional => true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper
  include ApplicationHelper

  respond_to :js, only: [:new, :create, :edit, :update, :show]

  has_scope :by_users

  helper_method :assignable_users, :status_counters

  before_filter :set_body_class, only: :index

  def autocomplete
    buckets = autocomplete_buckets({
      tasks: [Task],
      campaigns: [Campaign]
    }.merge(is_my_teams_view? ? {people: [CompanyUser, Team]} : {}))

    render :json => buckets.flatten
  end

  def assignable_users
    users = []
    unless resource.event.nil?
      users =  company_users.active.by_events(resource.event)
      users += company_users.active.by_teams(resource.event.teams)
      users.uniq!
    end
    users.sort{|a,b| a.name <=> b.name}
  end

  private
    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search


        f.push(label: "Campaigns", items: facet_search.facet(:campaign).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :campaign, count: x.count}) })
        #f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
        f.push(label: "Status", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
        if is_my_teams_view?
          users_count = Hash[facet_search.facet(:company_user_id).rows.map{|x| [x.value, x.count]}]
          users = current_company.company_users.includes(:user).where(id: facet_search.facet(:company_user_id).rows.map{|x| x.value})
          users = users.map{|x|  build_facet_item({label: x.full_name, id: x.id, name: :user, count: users_count[x.id]}) }
          teams = company_teams.joins(:users).where(company_users: {id: users_count.keys}).group('teams.id')
          teams = teams.map do |team|
            user_ids = team.user_ids
            build_facet_item({label: team.name, id: team.id, name: :team, count: user_ids.map{|id| users_count.has_key?(id) ? users_count[id] : 0 }.sum})
          end
          people = (users + teams).sort { |a, b| b[:count] <=> a[:count] }
          f.push(label: "Staff", items: people)
        end
      end
    end

    def status_counters
      @status_counters ||= Hash.new.tap do |counters|
        counters['unassigned'] = 0
        counters['completed'] = 0
        counters['assigned'] = 0
        counters['late'] = count_late_events
        facet_search.facet(:statusm).rows.map{|x| counters[x.value.downcase] = x.count } unless facet_search.facet(:statusm).nil?
      end
      @status_counters
    end

    def facet_search
      @facet_search ||= begin
        p = HashWithIndifferentAccess.new(facet_params)
        resource_class.do_search(p, true)
      end
    end

    def count_late_events
      @count_late_events ||= begin
        count_params = HashWithIndifferentAccess.new(facet_params.merge({late: true}))
        search = resource_class.do_search(count_params, true)
        search.total
      end
    end

    def facet_params
      search_params.select{|k, v| [:q, :start_date, :end_date, :user, :company_id, :event_id].include?(k.to_sym)}
    end

    def parent
      if params[:scope] == 'user'
        current_company_user
      else
        super
      end
    end

    def search_params
      @search_params ||= begin
        super
        unless @search_params.has_key?(:user) && !@search_params[:user].empty?
          @search_params[:user] = current_company_user.id if params[:scope] == 'user'
          @search_params[:user] = CompanyUser.joins(:teams).where(teams: {id: current_company_user.teams.select('teams.id').active.map(&:id)}).map(&:id).uniq.reject{|id| id == current_company_user.id } if params[:scope] == 'teams'
          @search_params[:user] = [0] if params[:scope] == 'teams' && @search_params[:user].empty?
        end
        @search_params
      end
    end

    def set_body_class
      @custom_body_class = params[:scope]
    end

    def is_my_teams_view?
      params[:scope] == 'teams'
    end

    def is_my_tasks_view?
      params[:scope] == 'user'
    end
end
