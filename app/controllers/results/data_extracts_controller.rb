class Results::DataExtractsController < InheritedResources::Base
  include ExportableController

  respond_to :js, only: [:new, :create, :show, :update, :edit]

  helper_method :return_path, :process_step, :resource, :form_action, :collection_count

  before_action :initialize_resource, only: [:new, :preview, :show, :items]
  before_action :enqueue_export, only: [:new, :show]

  set_callback :export, :initialize_resource

  def preview
    render layout: false
  end

  def available_fields
    render layout: false
  end

  def create
    if resource.save && resource.errors.empty?
      redirect_to results_reports_path
    else
      render layout: false
    end
  end

  def update
    if resource.update_attributes(extract_params) && resource.errors.empty?
      redirect_to results_reports_path
    else
      render layout: false
    end
  end

  def items
    render layout: false
  end

  def collection_count
    @collection_count ||= resource.total_results
  end

  def deactivate
    resource.deactivate! if resource.active == true
    render 'deactivate_data_extract'
  end

  def activate
    resource.activate! unless resource.active == true
    render 'deactivate_data_extract'
  end

  protected

  def collection_to_csv
    CSV.generate do |csv|
      csv << resource.columns_with_names.map { |c| c[1] }
      each_extract_page do |page|
        page.each { |row| csv << row }
      end
    end
  end

  def export_file_name
    "#{params[:data_extract][:source].pluralize}-export-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  # TODO: perhaps we should use a PG cursor here to speed up the export.
  # maybe using: https://github.com/afair/postgresql_cursor
  def each_extract_page
    items_per_page = 500
    total_pages = (collection_count / items_per_page.to_f).ceil
    (1..(total_pages)).each do |page|
      yield resource.rows(page, per_page: items_per_page)
      @_export.update_column(
        :progress, (page * 100 / total_pages).round) unless @_export.nil?
    end
  end

  def initialize_resource
    resource.current_user = current_company_user
    resource.filters = filter_params
  end

  def filter_params
    excluded_keys = [:action, :data_extact, :cotroller, :format, :page, :sorting, :sorting_dir,
                     :commit, :step, :utf, :source]
    params.reject { |k, _| excluded_keys.include?(k) }
  end

  def resource
    @data_extract ||=
      if params[:id]
        DataExtract.find(params[:id])
      elsif params.key?(:data_extract) && params[:data_extract][:source]
        search_filter_params
        if params[:data_extract][:source] == 'event_data'
          DataExtract::EventData.new(extract_params)
        else
          "DataExtract::#{params[:data_extract][:source].classify}".constantize.new(extract_params)
        end
      else
        current_company.data_extracts.new
      end
  end

  def extract_params
    params.require(:data_extract).permit([
      :name, :description, :default_sort_by, :default_sort_dir,
      columns: [], params: { campaign_id: [], activity_type_id: [] }
    ]).merge(company: current_company)
  end

  def process_step
    params[:step].nil? ? 1 : params[:step].to_i
  end

  def form_action(params_extract = '')
    if resource.new_record?
      new_results_data_extract_path(params_extract)
    else
      edit_results_data_extract_path(params_extract)
    end
  end

  def search_filter_params
    @search_params ||= params.dup.tap do |par|
      CustomFilter.where(id: params[:cfid]).each do |cf|
        par[:end_date] = params[:start_date] if params.key?('start_date') && !params.key?('end_date')
        par.deep_merge!(Rack::Utils.parse_nested_query(cf.filters)) do |key, v1, v2|
          if %w(start_date end_date).include?(key)
            Array(v1) + Array(v2)
          else
            (Array(v1) + Array(v2)).uniq
          end
        end
      end if params[:cfid].present?
    end
  end
end