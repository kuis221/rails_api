class BrandAmbassadors::DocumentFoldersController < InheritedResources::Base
  respond_to :js, only: [:new, :create]

  belongs_to :brand_ambassadors_visit, param: :visit_id, optional: true

  defaults resource_class: ::DocumentFolder

  include DeactivableHelper

  def index
    @folder_children = (
      parent_document_folders.where(parent_id: params[:parent_id]) +
      folder.brand_ambassadors_documents.active.where(folder_id: params[:parent_id])
    ).sort_by { |a| a.name.downcase }
    # ).sort{|a, b| a.name.downcase! <=> b.name.downcase!}
  end

  private

  def folder
    folders_chain = if params[:visit_id]
                      current_company.brand_ambassadors_visits.find(params[:visit_id]).document_folders
    else
      current_company.document_folders
    end
    @folder ||= params[:parent_id] ? folders_chain.find(params[:parent_id]) : (params[:visit_id] ? parent : current_company)
  end

  def parent_document_folders
    if params[:visit_id]
      folder.document_folders.active
    else
      folder.document_folders.active.where(folderable_id: current_company.id, folderable_type: 'Company')
    end
  end

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(document_folder: [:name, :parent_id])[:document_folder]
  end

  def begin_of_association_chain
    params[:visit_id].present? ? current_company : super
  end
end
