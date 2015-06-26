# Events Controller class
#
# This class handle the requests for the Events
#
class EventsController < FilteredController
  belongs_to :venue, optional: true

  # before_action :search_params, only: [:index, :filters, :items]

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to export HTML to PDF
  extend ExportableFormHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController
  include EventsHelper
  include ApplicationHelper

  # Handle the noticaitions for new events
  include NotificableController

  helper_method :calendar_highlights, :event_activities

  respond_to :js, only: [:new, :create, :edit, :update, :edit_results,
                         :edit_data, :edit_surveys, :submit]
  respond_to :json, only: [:map, :calendar_highlights]
  respond_to :xls, :pdf, only: :index

  custom_actions member: [:attendance, :edit_results, :edit_data, :edit_surveys]
  layout false, only: [:attendance]

  before_action :check_activities_message, only: :show

  skip_load_and_authorize_resource only: :update
  before_action :authorize_update, only: :update

  def map
    search_params.merge!(search_permission: :view_map)
    collection
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
    flash[:event_message_success] = I18n.translate('instructive_messages.execute.submit.success')
    rescue AASM::InvalidTransition => e
      Rails.logger.debug e.message
  end

  def approve
    resource.approve! if resource.submitted?
    flash[:event_message_fail] = resource.errors.full_messages.join('<br>') if resource.errors.any?
    redirect_to resource_path(status: 'approved')
  end

  def unapprove
    resource.unapprove! if resource.approved?
    flash[:event_message_success] = I18n.translate('instructive_messages.results.unapprove') if resource.errors.empty?
    redirect_to resource_path(status: 'unapproved')
  end

  def reject
    reject_reason = params[:reason]
    return unless resource.submitted? && reject_reason.present?

    resource.reject!
    resource.update_columns(reject_reason: reject_reason, rejected_at: Time.now)
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
    flash[:event_message_fail] = I18n.translate('instructive_messages.results.rejected')
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

  def pdf_form_file_name
    "#{resource.campaign_name.parameterize}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

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
      parameters = params.require(:event).permit(:visit_id, :campaign_id) if params[:event]
      parameters[:start_date] = t.to_s(:slashes)
      parameters[:start_time] = t.to_s(:time_only)

      t += 1.hour
      parameters[:end_date] = t.to_s(:slashes)
      parameters[:end_time] = t.to_s(:time_only)
    else
      allowed = []
      if can?(:update, Event) || can?(:create, Event)
        allowed.concat([
          :end_date, :end_time, :start_date, :start_time, :campaign_id, :visit_id,
          :place_id, :place_reference, :description, :visit_id, { team_members: [] }])
      end
      if can?(:edit_data, Event)
        allowed.concat([
          { results_attributes: [:id, :form_field_id, :value, { value: [] }] }])
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

    fail CanCan::AccessDenied, unauthorized_message(:update, resource)
  end

  def calendar_brands_events
    events_calendar_builder.group(params[:group])
  end

  def events_calendar_builder
    @calendar_builder ||= EventsCalendar.new(current_company_user, params)
  end

  def search_params
    @search_params || (super.tap do |p|
      p[:sorting] ||= Event.search_start_date_field
      p[:sorting_dir] ||= 'asc'
      p[:search_permission] = :view_list

      # Get a list of new events notifications to obtain the
      # list of ids, then delete them as they are already seen, but
      # store them in the session to allow the user to navigate, paginate, etc
      if params.key?(:new_at) && params[:new_at]
        p[:id] = session["new_events_at_#{params[:new_at].to_i}"] ||= begin
          ids = if params.key?(:notification) && params[:notification] == 'new_team_event'
                  current_company_user.notifications.new_team_events.pluck("params->'event_id'")
                else
                  current_company_user.notifications.new_events.pluck("params->'event_id'")
                end
          current_company_user.notifications.where("params->'event_id' in (?)", ids).destroy_all
          ids
        end
      end
    end)
  end

  def list_exportable?
    params['mode'] == 'calendar' || super
  end

  def default_url_options
    options = super
    options[:phase] = params[:phase] if params[:phase]
    options
  end

  def check_activities_message
    return unless params[:activity_form].present? &&
                  params[:activity_type_id].present? &&
                  session["activity_create_#{params[:activity_form]}"]
    activity_type = current_company.activity_types.find(params[:activity_type_id])
    flash[:event_message_success] = I18n.translate('instructive_messages.execute.activity.added',
                                                   count: session["activity_create_#{params[:activity_form]}"].to_i,
                                                   activity_type: activity_type.name)
    session.delete "activity_create_#{params[:activity_form]}"
  end
end
