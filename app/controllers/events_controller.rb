class EventsController < FilteredController
  belongs_to :venue, :optional => true

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper
  include EventsHelper
  include ApplicationHelper

  helper_method :describe_filters, :calendar_highlights

  respond_to :js, only: [:new, :create, :edit, :update, :edit_results, :edit_data, :edit_surveys, :submit]
  respond_to :json, only: [:index, :calendar_highlights]
  respond_to :xlsx, only: :index

  custom_actions member: [:tasks, :edit_results, :edit_data, :edit_surveys]
  layout false, only: :tasks

  skip_load_and_authorize_resource only: :update
  before_filter :authorize_update, only: :update
  
  after_filter :add_current_company_user, only: :create
  
  def add_current_company_user
    memberable = resource.memberships.build({company_user: current_company.company_users.find(current_company_user.id)}, without_protection: true)
    memberable.save
  end

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Venue, Area],
      people: [CompanyUser, Team]
    })
    render :json => buckets.flatten
  end

  def submit
    if resource.unsent? || resource.rejected?
      begin
        resource.submit!
      rescue AASM::InvalidTransition => e
      end
    end
  end

  def approve
    if resource.submitted?
      resource.approve!
      raise resource.errors.full_messages if resource.errors.any?
    end
    flash[:alert] = resource.errors.full_messages if resource.errors.any?
    redirect_to resource_path(:status => 'approved')
  end

  def reject
    reject_reason = params[:reason]
    if resource.submitted? && reject_reason.present?
      resource.reject!
      resource.update_column(:reject_reason, reject_reason)
    end
  end

  def calendar
    render json: calendar_brands_events
  end

  def calendar_highlights
    @calendar_highlights ||= Hash.new.tap do |hsh|
      tz = ActiveSupport::TimeZone.zones_map[Time.zone.name].tzinfo.identifier
      Event.select("to_char(TIMEZONE('UTC', start_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD') as start, to_char(TIMEZONE('UTC', end_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD') as end, count(events.id) as count")
        .where(company_id: current_company, active: true)
        .for_campaigns_accessible_by(current_company_user)
        .group("to_char(TIMEZONE('UTC', start_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD'), to_char(TIMEZONE('UTC', end_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD')").each do |result|
          the_start = Timeliness.parse(result.start).to_date
          the_end = Timeliness.parse(result.end).to_date
          (the_start..the_end).each do |day|
            parts = day.to_s(:ymd).split('/').map(&:to_i)
            hsh.merge!({parts[0] => {parts[1] => {parts[2] => result.count.to_i}}}){|year, months1, months2| months1.merge(months2) {|month, days1, days2| days1.merge(days2){|day, day_count1, day_count2| day_count1 + day_count2} }  }
          end
      end
      hsh
    end
  end

  protected

    def build_resource
      super
      if action_name == 'new' && params[:event]
        @event.assign_attributes(params.permit(event: [:place_reference])[:event])
      end
      @event
    end

    def permitted_params
      parameters = {}
      if action_name == 'new'
        t= Time.zone.now.beginning_of_hour
        t =  [t, t+15.minutes, t+30.minutes, t+45.minutes, t+1.hour].detect{|a| Time.zone.now < a }
        parameters[:start_date] = t.to_s(:slashes)
        parameters[:start_time] = t.to_s(:time_only)

        t = t + 1.hour
        parameters[:end_date] = t.to_s(:slashes)
        parameters[:end_time] = t.to_s(:time_only)
      else
        allowed = []
        allowed += [:end_date, :end_time, :start_date, :start_time, :campaign_id, :place_id, :place_reference] if can?(:update, Event) || can?(:create, Event)
        allowed += [:summary, {results_attributes: [:form_field_id, :kpi_id, :kpis_segment_id, :value, {value: []}, :id]}] if can?(:edit_data, Event)
        parameters = params.require(:event).permit(*allowed)
      end
      parameters
    end

    def authorize_update
      can?(:update, resource) || can?(:edit_data, resource)
    end

    def calendar_brands_events
      colors = ['#d3c941', '#606060', '#a18740', '#d93f99', '#a766cf', '#7e42a4', '#d7a23c',  '#6c5f3c', '#bfbfbf', '#909090']
      brands_colors = {}
      days = {}
      campaing_brands_map = {}
      start_date = DateTime.strptime(params[:start],'%s')
      end_date = DateTime.strptime(params[:end],'%s')
      p = search_params.merge(start_date: nil, end_date: nil)
      search = Event.do_search(p, true)
      #raise search.facet(:start_at).inspect
      campaign_ids = search.facet(:campaign_id).rows.map{|r| r.value.to_i }
      current_company.campaigns.where(id: campaign_ids).map{|campaign| campaing_brands_map[campaign.id] = campaign.associated_brands }

      all_brands = campaing_brands_map.values.flatten.map(&:id).uniq

      search = Event.do_search(p.merge(start_date: start_date.to_s(:slashes), end_date: end_date.to_s(:slashes), per_page: 1000))
      search.hits.each do |hit|
        sd = hit.stored(:start_at).in_time_zone.to_date
        ed = hit.stored(:end_at).in_time_zone.to_date
        (sd..ed).each do |day|
          days[day] ||= {}
          campaing_brands_map[hit.stored(:campaign_id).to_i].each do |brand|
            days[day][brand.id] ||= {count: 0, title: brand.name, start: day, end: day, color: colors[all_brands.index(brand.id)%colors.count], url: events_path('brand[]' => brand.id, 'start_date' => day.to_s(:slashes))}
            days[day][brand.id][:count] += 1
            days[day][brand.id][:description] = "<b>#{brand.name}</b><br />#{days[day][brand.id][:count]} Events"
          end
        end
      end
      days.map{|d, brands| brands.values.sort{|a, b| a[:title] <=> b[:title]}}.flatten
    end

    def search_params
      @search_params ||= begin
        super
        if request.format.xlsx?
          @search_params[:sorting] = 'start_at'
          @search_params[:sorting_dir] = 'asc'
        end
        @search_params
      end
    end
end
