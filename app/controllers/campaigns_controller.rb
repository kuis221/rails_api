# Campaigns Controller class
#
# This class handle the requests for managing the Campaigns
#
class CampaignsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update, :new_date_range]
  respond_to :json, only: [:show, :update]

  before_action :search_params, only: [:index]

  include DeactivableHelper

  # This helper provide the methods to add/remove campaigns members to the event
  extend TeamMembersHelper

  skip_authorize_resource only: :tab

  layout false, only: :kpis

  def update
    update! do |success, failure|
      success.js { render }
      success.json { render json: { result: 'OK' } }
      failure.json do
        render json: {
          result: 'KO', message: resource.errors.full_messages.join('<br />') }
      end
    end
  end

  def autocomplete
    buckets = autocomplete_buckets(
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Venue],
      people: [CompanyUser, Team]
    )
    render json: buckets.flatten
  end

  def find_similar_kpi
    search = Sunspot.search(Kpi) do
      keywords(params[:name]) do
        fields(:name)
      end
      with(:company_id, [-1, current_company.id])
    end
    render json: search.results
  end

  def remove_kpi
    @field = resource.form_fields.where(kpi_id: params[:kpi_id]).first
    @field.destroy
  end

  def add_kpi
    if resource.form_fields.where(kpi_id: params[:kpi_id]).count == 0
      @kpi = Kpi.global_and_custom(current_company).find(params[:kpi_id])
      @field = resource.add_kpi(@kpi)
    else
      render text: ''
    end
  end

  def select_kpis
    @kpis = (
      Kpi.campaign_assignable(resource) +
      current_company.activity_types.where.not(id: resource.activity_type_ids).active
    ).sort_by(&:name)
  end

  def remove_activity_type
    activity_type = current_company.activity_types.find(params[:activity_type_id])
    if resource.activity_types.include?(activity_type)
      resource.activity_types.delete(activity_type)
    else
      render text: ''
    end
  end

  def add_activity_type
    if resource.activity_types.exists?(params[:activity_type_id])
      render text: ''
    else
      activity_type = current_company.activity_types.find(params[:activity_type_id])
      resource.activity_types << activity_type
    end
  end

  def new_date_range
    @date_ranges = current_company.date_ranges
      .where('date_ranges.id not in (?)', resource.date_range_ids + [0])
  end

  def add_date_range
    return if resource.date_ranges.exists?(params[:date_range_id])
    resource.date_ranges << current_company.date_ranges.find(params[:date_range_id])
  end

  def delete_date_range
    date_range = resource.date_ranges.find(params[:date_range_id])
    resource.date_ranges.delete(date_range)
  end

  def new_day_part
    @day_parts = current_company.day_parts
      .where('day_parts.id not in (?)', resource.day_part_ids + [0])
  end

  def add_day_part
    return if resource.day_parts.exists?(params[:day_part_id])
    resource.day_parts << current_company.day_parts.find(params[:day_part_id])
  end

  def delete_day_part
    day_part = resource.day_parts.find(params[:day_part_id])
    resource.day_parts.delete(day_part)
  end

  def tab
    authorize! "view_#{params[:tab]}", resource
    render layout: false
  end

  protected

  def permitted_params
    p = [:name, :start_date, :end_date, :description, :color, :brands_list, { brand_portfolio_ids: [] }]
    if can?(:view_event_form, Campaign)
      p.push(
        survey_brand_ids: [],
        form_fields_attributes: [
          :id, :name, :field_type, :ordering, :required, :_destroy, :kpi_id,
          { settings: [:description, :range_min, :range_max, :range_format,
                       { disabled_segments: [] }] },
          { options_attributes: [:id, :name, :_destroy, :ordering] },
          { statements_attributes: [:id, :name, :_destroy, :ordering] }])
    end
    attrs = params.permit(campaign: p)[:campaign].tap do |whitelisted|
      if params[:campaign] && params[:campaign].key?(:modules) && can?(:view_event_form, Campaign)
        whitelisted[:modules] = params[:campaign][:modules]
      end
    end

    if attrs && attrs[:survey_brand_ids].present? && attrs[:survey_brand_ids].any?
      normalize_brands attrs[:survey_brand_ids]
    end

    # Workaround to deal with jQuery not sending empty arrays
    if attrs && attrs[:modules].present? && attrs[:modules].key?('empty')
      attrs[:modules] = {}
    end

    attrs
  end

  def normalize_brands(brands)
    return if brands.empty?

    brands.each_with_index do |b, index|
      unless b.is_a?(Integer) || b =~ /\A[0-9]+\z/
        b = current_company.brands.where('lower(name) = ?', b.downcase).pluck(:id).first ||
            current_company.brands.create(name: b).id
      end
      brands[index] = b.to_i
    end
  end

  def facets
    @facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      f.push build_brands_bucket
      f.push build_brand_portfolio_bucket

      f.push build_people_bucket
      f.push build_state_bucket
    end
  end

  def search_params
    @search_params ||= begin
      super

      # Get a list of new campaigns notifications to obtain the list of ids,
      # then delete them as they are already seen, but
      # store them in the session to allow the user to navigate, paginate, etc
      if params.key?(:new_at) && params[:new_at]
        @search_params[:id] = session["new_campaigns_at_#{params[:new_at].to_i}"] ||= begin
          notifications = current_company_user.notifications.new_campaigns
          ids = notifications.map { |n| n.params['campaign_id'] }.compact
          notifications.destroy_all
          ids
        end
      end
      @search_params
    end
  end
end
