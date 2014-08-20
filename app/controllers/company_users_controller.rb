class CompanyUsersController < FilteredController
  include DeactivableHelper
  include UsersHelper

  respond_to :js, only: [:new, :create, :edit, :update, :time_zone_change,:time_zone_update ]
  respond_to :json, only: [:index, :notifications]

  helper_method :brands_campaigns_list, :viewing_profile?

  custom_actions collection: [:complete, :time_zone_change, :time_zone_update]

  before_action :validate_parent, only: [:enable_campaigns, :disable_campaigns, :remove_campaign, :select_campaigns, :add_campaign]

  skip_load_and_authorize_resource only: [:export_status]

  def autocomplete
    buckets = autocomplete_buckets({
      users: [CompanyUser],
      teams: [Team],
      roles: [Role],
      campaigns: [Campaign],
      places: [Venue]
    })

    render :json => buckets.flatten
  end

  def profile
    @company_user = current_company_user
    render :show
  end

  def update
    resource.user.updating_user = true if can?(:super_update, resource)
    update! do |success, failure|
      success.js {
        if resource.user.id == current_user.id
          sign_in resource.user, :bypass => true
        elsif resource.invited_to_sign_up?
          resource.user.accept_invitation!
        end
      }
      failure.js {
        if params[:company_user][:user_attributes][:verification_code]
          render 'verify_phone'
        end
      }
    end
  end

  def verify_phone
    if resource.user.phone_number.present?
      resource.user.generate_and_send_phone_verification_code
    end
  end

  def time_zone_change
    current_user.update_column(:detected_time_zone, params[:time_zone])
  end

  def time_zone_update
    current_user.update_column(:time_zone, params[:time_zone])
    render nothing: true
  end

  def select_company
    begin
      company_user = current_user.company_users.find_by(company_id: params[:company_id], active: true) or raise ActiveRecord::RecordNotFound
      current_user.current_company = company_user.company
      current_user.update_column(:current_company_id, company_user.company.id)
      session[:current_company_id] = company_user.company_id
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "You are not allowed login into this company"
    end
    redirect_to root_path
  end

  def enable_campaigns
    if params[:parent_type] && params[:parent_id]
      parent_membership = resource.memberships.find_or_create_by(memberable_type: params[:parent_type], memberable_id: params[:parent_id])
      @parent = parent_membership.memberable
      @campaigns = @parent.campaigns
      # Delete all campaign associations assigned to this user directly under this brand/portfolio
      resource.memberships.where(parent_id: parent_membership.memberable.id, parent_type: parent_membership.memberable.class.name).destroy_all
    end
  end

  def disable_campaigns
    if params[:parent_type] && params[:parent_id]
      membership = resource.memberships.find_by(memberable_type: params[:parent_type], memberable_id: params[:parent_id])
      unless membership.nil?
        resource.memberships.where(parent_id: membership.memberable.id, parent_type: membership.memberable.class.name).destroy_all
        # Assign all the campaings directly to the user
        membership.memberable.campaigns.each do |campaign|
          resource.memberships.create(memberable: campaign, parent: membership.memberable)
        end
        membership.destroy
      end
    end
    render text: 'OK'
  end

  def remove_campaign
    if params[:campaign_id]
      if params[:parent_type]
        membership = resource.memberships.where(memberable_type: params[:parent_type], memberable_id: params[:parent_id]).first
      else
        membership = nil
      end
      # If the parent is directly assigned to the user, then remove the parent and assign all the
      # current campaigns to the user
      unless membership.nil?
        membership.memberable.campaigns.where(company_id: current_company.id).each do |campaign|
          unless campaign.id == params[:campaign_id].to_i
            resource.memberships.create(memberable: campaign, parent: membership.memberable)
          end
        end
        membership.destroy
      else
        membership = resource.memberships.where(parent_type: params[:parent_type], parent_id: params[:parent_id], memberable_type: 'Campaign', memberable_id: params[:campaign_id]).destroy_all
      end
    end
  end

  def select_campaigns
    @campaigns = []
    if params[:parent_type] && params[:parent_id]
      membership = resource.memberships.where(memberable_type: params[:parent_type], memberable_id: params[:parent_id]).first
      if membership.nil?
        parent = params['parent_type'].constantize.find(params['parent_id'])
        @campaigns = parent.campaigns.where(company_id: current_company.id).where(['campaigns.id not in (?)', resource.campaigns.children_of(parent).map(&:id)+[0]])
      end
    end
  end

  def add_campaign
    if params[:parent_type] && params[:parent_id] && params[:campaign_id]
      @parent = params['parent_type'].constantize.find(params['parent_id'])
      campaign = current_company.campaigns.find(params[:campaign_id])
      resource.memberships.create(memberable: campaign, parent: @parent)
      @campaigns = resource.campaigns.children_of(@parent)
    end
  end

  def export_status
    url = nil
    export = ListExport.find_by(id: params[:download_id], company_user_id: current_company_user.id)
    url = export.download_url if export.completed? && export.file_file_name
    respond_to do |format|
      format.json { render json:  {status: export.aasm_state, progress: export.progress, url: url} }
    end
  end

  def notifications
    alerts = notifications_for_company_user(current_company_user)

    render json: alerts
  end

  def dismiss_alert
    current_company_user.dismiss_alert params[:name], params[:version]
    render text: ''
  end

  protected
    def permitted_params
      allowed = {
        company_user: [
          {user_attributes: [
            :id, :first_name, :last_name, :email, :phone_number,
            :password, :password_confirmation, :country, :state, :verification_code,
            :city, :street_address, :unit_number, :zip_code, :time_zone]},
          :notifications_settings => []] }
      if params[:id].present? && can?(:super_update, CompanyUser.find(params[:id]))
        allowed[:company_user] += [:role_id, {team_ids: []}]
      end
      params.permit(allowed)[:company_user]
    end

    def roles
      @roles ||= current_company.roles
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| %w(q company_id current_company_user).include?(k)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push build_role_bucket facet_search
        f.push build_campaign_bucket
        f.push build_team_bucket facet_search
        # f.push(label: "Active State", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
        f.push build_state_bucket
      end
    end

    def build_state_bucket
      items = ['Active', 'Inactive', 'Invited'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) }
      items = items.sort{|a, b| a[:label] <=> b[:label]}
      {label: "Active State", items: items}
    end

    def delete_member_path(user)
      path = nil
      path = delete_member_team_path(params[:team], member_id: user.id) if params.has_key?(:team) && params[:team]
      path = delete_member_campaign_path(params[:campaign], member_id: user.id) if params.has_key?(:campaign) && params[:campaign]
      path
    end

    def brands_campaigns_list
      list = {}
      current_company.brand_portfolios.active.each do |portfolio|
        enabled = resource.brand_portfolios.include?(portfolio)
        list[portfolio] = {enabled: enabled, campaigns: (enabled ? portfolio.campaigns.where(company_id: current_company.id) : resource.campaigns.where(company_id: current_company.id).children_of(portfolio) ) }
      end
      current_company.brands.active.each do |brand|
        enabled = resource.brands.include?(brand)
        list[brand] = {enabled: enabled, campaigns: (enabled ? brand.campaigns.where(company_id: current_company.id) : resource.campaigns.where(company_id: current_company.id).children_of(brand) ) }
      end
      list
    end

    def validate_parent
      raise CanCan::AccessDenied unless ['BrandPortfolio', 'Brand'].include?(params[:parent_type]) || params[:parent_type].nil?
    end

    def viewing_profile?
      action_name == 'profile'
    end

end
