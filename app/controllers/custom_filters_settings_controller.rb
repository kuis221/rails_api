# Custom Filters Settings Controller class
#
# This class handle the requests for managing the Custom Filters Settings
#
class CustomFiltersSettingsController < InheritedResources::Base
  
  respond_to :js, only: [:index, :new, :create]
  
  actions :index, :new, :create

  belongs_to :custom_filter, optional: true

   helper_method :modal_dialog_title

  def index
  end

  def new
    @custom_filter = CustomFilter.new
    respond_with(@custom_filter)
  end

  protected

  def modal_dialog_title
    p "---------------------------->"
   p I18n.translate(
      "modals.title.#{resource.new_record? ? 'new' : 'edit'}.custom_filter",
      name: resource.try(:name))
  end
end