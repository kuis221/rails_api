class Results::DataExtractsController < InheritedResources::Base
  respond_to :js, only: [:new, :create]

  helper_method :return_path

  def new
    permitted_params
    if params[:data_source].present? 
      init_configure 
    else
      @step = 1
    end
  end

  protected

  def permitted_params
    params.permit([:data_source, :step, available_fields: [], selected_fields: []])
  end

  def init_configure
    @step = 2
    source = 'DataExtract::' + params[:data_source].humanize.split.map(&:capitalize)*''
    @data_source = source.constantize.new(company: current_company)
    @available_fields = params[:available_fields] || []
    @selected_fields = params[:selected_fields] || @data_source.exportable_columns
  end
end