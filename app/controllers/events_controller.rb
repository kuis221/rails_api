# Events Controller class
#
# This class handle the requests for the Events
#
class EventsController < FilteredController
  belongs_to :venue, optional: true

  # before_action :search_params, only: [:index, :filters, :items]

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper
  include EventsHelper
  include ApplicationHelper

  helper_method :describe_filters, :calendar_highlights

  respond_to :js, only: [:new, :create, :edit, :update, :edit_results,
                         :edit_data, :edit_surveys, :submit]
  respond_to :json, only: [:index, :calendar_highlights]
  respond_to :xls, only: :index
  respond_to :xls, only: :index

  custom_actions member: [:tasks, :edit_results, :edit_data, :edit_surveys]
  layout false, only: :tasks

  skip_load_and_authorize_resource only: :update
  before_action :authorize_update, only: :update

  def autocomplete
    buckets = autocomplete_buckets(
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Venue, Area],
      people: [CompanyUser, Team]
    )
    render json: buckets.flatten
  end

  def submit
    return unless resource.unsent? || resource.rejected?
    resource.submit!
    resource.users.each do |company_user|
      if company_user.allow_notification?('event_recap_pending_approval_sms')
        sms_message = I18n.translate(
          'notifications_sms.event_recap_pending_approval',
          url: Rails.application.routes.url_helpers.event_url(resource))
        Resque.enqueue(SendSmsWorker, company_user.phone_number, sms_message)
      end
      if company_user.allow_notification?('event_recap_pending_approval_email')
        email_message = I18n.translate(
          'notifications_email.event_recap_pending_approval',
          url: Rails.application.routes.url_helpers.event_url(resource))
        UserMailer.notification(
          company_user.id,
          I18n.translate('notification_types.event_recap_pending_approval'),
          email_message).deliver
      end
    end
    rescue AASM::InvalidTransition => e
      Rails.logger.debug e.message
  end

  def approve
    resource.approve! if resource.submitted?
    flash[:alert] = resource.errors.full_messages if resource.errors.any?
    redirect_to resource_path(status: 'approved', return: params[:return])
  end

  def reject
    reject_reason = params[:reason]
    return unless resource.submitted? && reject_reason.present?

    resource.reject!
    resource.update_column(:reject_reason, reject_reason)
    resource.users.each do |company_user|
      if company_user.allow_notification?('event_recap_rejected_sms')
        sms_message = I18n.translate(
          'notifications_sms.event_recap_rejected',
          url: Rails.application.routes.url_helpers.event_url(resource))
        Resque.enqueue(SendSmsWorker, company_user.phone_number, sms_message)
      end
      if company_user.allow_notification?('event_recap_rejected_email')
        email_message = I18n.translate(
          'notifications_email.event_recap_rejected',
          url: Rails.application.routes.url_helpers.event_url(resource))
        UserMailer.notification(
          company_user.id,
          I18n.translate('notification_types.event_recap_rejected'),
          email_message
        ).deliver
      end
    end
  end

  def calendar
    render json: calendar_brands_events
  end

  def calendar_highlights
    @calendar_highlights ||= Hash.new.tap do |hsh|
      tz = ActiveSupport::TimeZone.zones_map[Time.zone.name].tzinfo.identifier
      events_scope = if current_company.timezone_support?
        Event.select(
          'to_char(local_start_at, \'YYYY/MM/DD\') as start,
           to_char(local_end_at, \'YYYY/MM/DD\') as end, count(events.id) as count')
      else
        Event.select(
          "to_char(TIMEZONE('UTC', start_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD') as start,
           to_char(TIMEZONE('UTC', end_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD') as end,
           count(events.id) as count")
      end.active.accessible_by_user(current_company_user)

      ActiveRecord::Base.connection.select_all(events_scope.group('1, 2').to_sql).each do |result|
        the_start = Timeliness.parse(result['start']).to_date
        the_end = Timeliness.parse(result['end']).to_date
        (the_start..the_end).each do |day|
          parts = day.to_s(:ymd).split('/').map(&:to_i)
          hsh.merge!(
            parts[0] => { parts[1] => { parts[2] => result['count'].to_i } }
          ) do |_, months1, months2|
            months1.merge(months2) do |_, days1, days2|
              days1.merge(days2) { |_, day_count1, day_count2| day_count1 + day_count2 }
            end
          end
        end
      end
      hsh
    end
  end

  protected

  def build_resource
    @event || super.tap do |e|
      super
      if action_name == 'new' && params[:event]
        e.assign_attributes(params.permit(event: [:place_reference])[:event])
      end
      e.user_ids = [current_company_user.id] if action_name == 'new'
    end
  end

  def begin_of_association_chain
    params[:visit_id] ? BrandAmbassadors::Visit.find(params[:visit_id]) : super
  end

  def permitted_params
    parameters = {}
    if action_name == 'new'
      t = Time.zone.now.beginning_of_hour
      t = [t, t + 15.minutes, t + 30.minutes, t + 45.minutes, t + 1.hour].find do |a|
        Time.zone.now < a
      end
      parameters[:start_date] = t.to_s(:slashes)
      parameters[:start_time] = t.to_s(:time_only)

      t += 1.hour
      parameters[:end_date] = t.to_s(:slashes)
      parameters[:end_time] = t.to_s(:time_only)
    else
      allowed = []
      if can?(:update, Event) || can?(:create, Event)
        allowed.concat([
          :end_date, :end_time, :start_date, :start_time, :campaign_id,
          :place_id, :place_reference, :description, :visit_id, { team_members: [] }])
      end
      if can?(:edit_data, Event)
        allowed.concat([
          :summary, { results_attributes: [:id, :form_field_id, :value, { value: [] }] }])
      end
      parameters = params.require(:event).permit(*allowed)
    end
    parameters.tap do |whielisted|
      unless whielisted.nil? || whielisted[:results_attributes].nil?
        whielisted[:results_attributes].each do |k, value|
          value[:value] = params[:event][:results_attributes][k][:value]
        end
      end
    end
  end

  def authorize_update
    return unless cannot?(:update, resource) && cannot?(:edit_data, resource)

    message = unauthorized_message(:update, resource)
    fail CanCan::AccessDenied, message
  end

  def calendar_brands_events
    colors = %w(#d3c941 #606060 #a18740 #d93f99 #a766cf #7e42a4 #d7a23c #6c5f3c #bfbfbf #909090)
    days = {}
    campaing_brands_map = {}
    start_date = DateTime.strptime(params[:start], '%s')
    end_date = DateTime.strptime(params[:end], '%s')
    custom_params = search_params.merge(start_date: nil, end_date: nil)
    search = Event.do_search(custom_params, true)
    campaign_ids = search.facet(:campaign_id).rows.map { |r| r.value.to_i }
    current_company.campaigns.where(id: campaign_ids).map do |campaign|
      campaing_brands_map[campaign.id] = campaign.associated_brand_ids
    end

    all_brands = campaing_brands_map.values.flatten.uniq
    brands = Hash[Brand.where(id: all_brands).map { |b| [b.id, b] }]

    search = Event.do_search(custom_params.merge(
        start_date: start_date.to_s(:slashes),
        end_date: end_date.to_s(:slashes),
        per_page: 1000
    ))
    search.hits.each do |hit|
      sd = hit.stored(:start_at).in_time_zone.to_date
      ed = hit.stored(:end_at).in_time_zone.to_date
      (sd..ed).each do |day|
        days[day] ||= {}
        next unless campaing_brands_map[hit.stored(:campaign_id).to_i]

        campaing_brands_map[hit.stored(:campaign_id).to_i].each do |brand_id|
          brand = brands[brand_id]
          days[day][brand.id] ||= {
            count: 0,
            title: brand.name,
            start: day,
            end: day,
            color: colors[all_brands.index(brand.id) % colors.count],
            url: events_path('brand[]' => brand.id, 'start_date' => day.to_s(:slashes)) }
          days[day][brand.id][:count] += 1
          days[day][brand.id][:description] = "<b>#{brand.name}</b><br />#{days[day][brand.id][:count]} Events"
        end
      end
    end
    days.map { |_, bs| bs.values.sort { |a, b| a[:title] <=> b[:title] } }.flatten
  end

  def search_params
    @search_params ||= begin
      super
      if request.format.xls?
        @search_params[:sorting] = 'start_at'
        @search_params[:sorting_dir] = 'asc'
      end

      # Get a list of new events notifications to obtain the
      # list of ids, then delete them as they are already seen, but
      # store them in the session to allow the user to navigate, paginate, etc
      if params.key?(:new_at) && params[:new_at]
        @search_params[:id] = session["new_events_at_#{params[:new_at].to_i}"] ||= begin
          ids = if params.key?(:notification) && params[:notification] == 'new_team_event'
                  current_company_user.notifications.new_team_events.pluck("params->'event_id'")
                else
                  current_company_user.notifications.new_events.pluck("params->'event_id'")
                end
          current_company_user.notifications.where("params->'event_id' in (?)", ids).destroy_all
          ids
        end
      end

      @search_params
    end
  end
end
