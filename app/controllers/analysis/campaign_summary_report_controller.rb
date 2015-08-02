class Analysis::CampaignSummaryReportController < InheritedResources::Base
  include ExportableController

  respond_to :pdf, only: :export_results

  helper_method :return_path, :collection_count
  before_action :initialize_campaign
  set_callback :export
  respond_to :csv, only: [:index]

  FIELD_TYPE = ['FormField::Number', 'FormField::Currency', 'FormField::Summation',
                'FormField::LikertScale', 'FormField::Percentage', 'FormField::Checkbox',
                'FormField::Radio', 'FormField::Dropdown', 'FormField::Brand']

  def export_results
    @event_scope = results_scope

    respond_to do |format|
      format.pdf do
        render pdf: pdf_form_file_name,
               layout: 'application.pdf',
               disposition: 'attachment',
               show_as_html: params[:debug].present?
      end
      format.html do
        render layout: 'application.pdf',
               disposition: 'attachment',
               show_as_html: params[:debug].present?
      end
    end
  end

  def report
    render layout: false
  end

  def result
    @event_scope = results_scope
    render layout: false
  end

  def results_scope
    s = Event.where(active: true).uniq
    s = s.in_areas(params['area']) if params['area'].present?
    s = in_places(s, params['place']) if params['place'].present?
    s = s.where(aasm_state: params['event_status'].map { |f| f.downcase}) if params['event_status'].present?
    s = s.filters_between_dates(params['start_date'].to_s, params['end_date'].to_s) if params['start_date'].present? && params['end_date'].present?
    s = s.joins('LEFT JOIN brands_campaigns ON brands_campaigns.campaign_id=events.campaign_id')
            .where("brands_campaigns.brand_id IN (#{params['brand'].join(', ')})").uniq if params['brand'].present?
    s = s.joins('LEFT JOIN memberships AS member_events ON member_events.memberable_type=\'Event\'')
          .where("member_events.memberable_id = events.id AND member_events.company_user_id IN (#{params['user'].join(', ')})").uniq if params['user'].present?
    s
  end

  def items
    @event_scope = results_scope
    render layout: false
  end

  def collection_count
    collection.count
  end

  def collection
    @campaign.present? ? @campaign.events.merge(results_scope) : []
  end

  protected

  def return_path
    analysis_path
  end

  def collection_to_csv
    params = @_export.params if @_exports.present?
    initialize_campaign
    CSV.generate do |csv|
      generate_results_csv.each do |_, row|
        csv << row
      end
    end
  end

  private

  def initialize_results_csv
    hash_result = { titles: [] }
    collection.inject(hash_result) do |hash, event|
      hash[event.id] = []
      hash
    end
  end

  def generate_results_csv
    hash_results = initialize_results_csv
    @campaign.form_fields.each do |form_field|
      form_field.csv_results(@campaign, results_scope, hash_results) if FIELD_TYPE.include?(form_field.type)
    end
    hash_results
  end

  def pdf_form_file_name
    "#{@campaign.name.parameterize}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  def set_cache_header
    response.headers['Cache-Control']='private, max-age=0, no-cache'
  end

  def initialize_campaign
    campaign_id ||= params[:campaign_summary] || (params[:report][:campaign_id] if params[:report] && params[:report][:campaign_id].present?)
    @campaign ||= current_company.campaigns.find(campaign_id) if campaign_id.present?
  end

  def in_places(s, places)
    places_list = Place.where(id: places)
    s = s.where(
      'events.place_id in (?) or events.place_id in (
          select place_id FROM locations_places where location_id in (?)
      )',
      places_list.map(&:id).uniq + [0],
      places_list.select(&:is_location?).map(&:location_id).compact.uniq + [0])
    s
  end
end