class TagsController < InheritedResources::Base
  belongs_to :attached_asset
  respond_to :js, only: [:activate, :deactivate]
 
 def deactivate
   parent.tags.delete resource
 end
 
 def activate
   resource = current_company.tags.find_by_id params[:id]
   if resource.nil?
     resource = current_company.tags.create(name: params[:id])
   end
   parent.tags << resource
 end

  protected
    def permitted_params
      params.permit(tag: [:name, :id])[:tag]
    end

end
