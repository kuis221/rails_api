class TagsController < InheritedResources::Base
 # actions :index, :new, :create
 # belongs_to :campaign, :brand_portfolio, optional: true
  respond_to :js, only: [:activate, :deactivate]
 
 def deactivate
   @tag = Tag.find params[:id]
   @photo = AttachedAsset.find params[:attached_asset_id]
   @photo.tags.delete @tag
 end
 
  def activate
   @tag = Tag.find_by_id params[:id]
   if @tag.nil?
     @tag = Tag.create(name: params[:id], company: current_company)
   end
   @photo = AttachedAsset.find params[:attached_asset_id]
   @photo.tags << @tag
   #render text: ''
 end

  protected
    def permitted_params
      params.permit(tag: [:name, :id])[:tag]
    end

    def authorize_actions
      authorize! :index, resource_class
    end
end
