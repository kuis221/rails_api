class Results::SurveysController < FilteredController

  defaults :resource_class => ::Event
  respond_to :xlsx, only: :index

  helper_method :expenses_total

  private
    def search_params
      @search_params ||= begin
        super
        unless @search_params.has_key?(:user) && !@search_params[:user].empty?
          @search_params[:with_surveys_only] = true
        end
        @search_params
      end
    end
end