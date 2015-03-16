class Results::DataExtractsController < InheritedResources::Base
  respond_to :js, only: [:new, :create]

  helper_method :return_path

  def new
    permitted_params
    if params[:data_source].present?
      @step = 2
    else
      @step = 1
      @data_sources = select_data_sources
    end      
  end

  protected

  def select_data_sources
    [
      ['Events', :event], ['Post Event Data (PERs)', :event_data], ['Activities', :activity],
      ['Attendance', :invite], ['Comments', :comment], ['Contacts', :contact], ['Expenses', :event_expense],
      ['Surveys', :survey], ['Tasks', :task], ['Venues', :venue], ['Users', :user], ['Teams', :team],
      ['Roles', :role], ['Campaign', :campaign], ['Brands', :brands], ['Activity Types', :activity_type],
      ['Areas', :area], ['Brand Porfolios', :brand_porfolio], ['Data Ranges', :date_range], ['Day Parts', :day_part]
    ]
  end

  def permitted_params
    params.permit([:data_source, :step])
  end
end
