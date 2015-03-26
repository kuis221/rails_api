class Results::DataExtractsController < InheritedResources::Base
  respond_to :js, only: [:new, :create]

  helper_method :return_path, :process_step, :resource, :form_action

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

  protected

  def resource
    @data_extract ||=
      if params[:id]
        DataExtract.find(params[:id])
      elsif params.key?(:data_extract) && params[:data_extract][:source]
        "DataExtract::#{params[:data_extract][:source].classify}".constantize.new(extract_params.merge(company: current_company))
      else
        current_company.data_extracts.new
      end
  end

  def extract_params
    params.require(:data_extract).permit([:name, :description, filters: [], columns: []])
  end

  def process_step
    params[:step].to_i || 1
  end

  def form_action
    if resource.new_record?
      new_results_data_extract_path
    else
      edit_results_data_extract_path
    end
  end
end