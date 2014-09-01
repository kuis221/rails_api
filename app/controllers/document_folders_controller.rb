class DocumentFoldersController < InheritedResources::Base
  respond_to :js, only: [:new, :create]

  belongs_to :brand_ambassadors_visit, param: :visit_id, optional: true

  include DeactivableHelper

  private
    def build_resource_params
      [permitted_params || {}]
    end
    def permitted_params
      params.permit(document_folder: [:name])[:document_folder]
    end

    def begin_of_association_chain
      params[:visit_id].present? ? current_company : super
    end
end