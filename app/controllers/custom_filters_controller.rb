# Custom Filters Controller class
#
# This class handle the requests for managing the Custom Filters
#
class CustomFiltersController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create, :destroy]
  respond_to :json, only: [:default_view]

  actions :index, :new, :create, :destroy, :update

  def create
    if permitted_params[:id]
      params[:id] = permitted_params[:id]
      update!
    else
      if params[:custom_filter][:start_date].present? || params[:custom_filter][:end_date].present?
        prepare_create
      end
      create!
    end
  end

  def default_view
    begin_of_association_chain.custom_filters.where(apply_to: resource.apply_to).update_all("default_view = false")
    resource.update_attribute(:default_view, true)
    render json: { result: 'OK' }
  end

  private

  def build_resource_params
    [permitted_params || {}]
  end

  def begin_of_association_chain
    (params[:company_id] ? current_company : current_company_user)
  end

  def permitted_params
    params.permit(custom_filter: [
      :id, :name, :apply_to, :filters, :default_view, :start_date, :end_date, :category_id])[:custom_filter]
  end

  def encode_uri(value)
    URI.escape(value, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  def prepare_create
    qs = ""
    if params[:custom_filter][:start_date].present?
      qs = "#{encode_uri("start_date")}=#{encode_uri(params[:custom_filter][:start_date])}"
    end
    if params[:custom_filter][:end_date].present?
      qs += qs ?  '&' : ''
      qs += "#{encode_uri("end_date")}=#{encode_uri(params[:custom_filter][:end_date])}"
    end
    params[:custom_filter][:filters] = qs
  end
end
