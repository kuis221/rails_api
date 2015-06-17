class TagsController < InheritedResources::Base
  belongs_to :attached_asset
  respond_to :js, only: [:activate, :remove]
  respond_to :json, only: [:index]

  helper_method :company_tags

  def remove
    authorize! :remove_tag, parent
    parent.tags.delete resource
  end

  def activate
    authorize! :activate_tag, parent
    parent.tags << load_tag
  end

  def index
    respond_to do |format|
      format.json { render json: company_tags }
    end
  end

  protected

  def load_tag
    @tag = current_company.tags.find_by_id params[:id] if params[:id] =~ /\A[0-9]+\z/
    @tag ||=
      if can?(:create, Tag)
        current_company.tags.find_or_create_by(name: params[:id])
      else
        current_company.tags.find_by(:name)
      end
    @tag
  end

  def permitted_params
    params.permit(tag: [:name, :id])[:tag]
  end

  def company_tags
    current_company.tags.order('name ASC').map { |t| { 'id' => t.id, 'text' => t.name } }
  end
end
