class MarquesController < FilteredController
  actions :index
  belongs_to :brand
  respond_to :json, only: [:index]

  protected
    def permitted_params
      params.permit(marque: [:name])[:marque]
    end

    def authorize_actions
      authorize! :index, resource_class
    end
end