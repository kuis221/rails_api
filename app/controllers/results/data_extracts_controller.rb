class Results::DataExtractsController < InheritedResources::Base
  include ExportableController

  respond_to :js, only: [:new, :create]

  helper_method :return_path, :process_step, :resource, :form_action, :collection_count

  before_action :initialize_resource, only: [:new, :preview, :show, :items]
  before_action :enqueue_export, only: [:new, :show]

  set_callback :export, :initialize_resource

  def new
  end

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

  def items
    render layout: false
  end

  def collection_count
    @collection_count ||= resource.total_results
  end

  protected

  def collection_to_csv
    CSV.generate do |csv|
      csv << resource.columns.map { |c| I18n.t("data_exports.fields.#{c}") }
      each_extract_page do |page|
        page.each { |row| csv << row }
      end
    end
  end

  def each_extract_page
    items_per_page = 100
    total_pages = (collection_count / items_per_page.to_f).ceil
    (1..(total_pages)).each do |page|
      yield resource.rows(page)
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
                     :commit, :step, :utf]
    params.reject { |k, _| excluded_keys.include?(k) }
  end

  def resource
    @data_extract ||=
      if params[:id]
        DataExtract.find(params[:id])
      elsif params.key?(:data_extract) && params[:data_extract][:source]
        if params[:data_extract][:source] == 'event_data'
          DataExtract::EventData.new(extract_params.merge(company: current_company))
        else
          "DataExtract::#{params[:data_extract][:source].classify}".constantize.new(extract_params.merge(company: current_company))
        end
      else
        current_company.data_extracts.new
      end
  end

  def extract_params
    params.require(:data_extract).permit([
      :name, :description, :default_sort_by, :default_sort_dir, filters: [], columns: []])
  end

  def process_step
    params[:step].to_i || 1
  end

  def form_action(params_extract = "")
    if resource.new_record?
      new_results_data_extract_path(params_extract)
    else
      edit_results_data_extract_path(params_extract)
    end
  end
end