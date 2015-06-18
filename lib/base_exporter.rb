class BaseExporter
  attr_accessor :params, :company_user, :resource_class

  def initialize(company_user, params)
    @company_user = company_user
    @params = params
  end

  def campaign_ids
    @campaign_ids ||= begin
      ids =
        if params[:campaign] && params[:campaign].any?
          params[:campaign].uniq.compact
        else
          []
        end
      unless company_user.is_admin?
        if ids.any?
          ids = ids.map(&:to_i) & company_user.accessible_campaign_ids
        else
          ids = company_user.accessible_campaign_ids
        end
      end
      filter_campaigns_by_brands(ids)
    end
  end

  def filter_campaigns_by_brands(campaign_ids)
    return campaign_ids unless params[:brand] && params[:brand].any?
    if campaign_ids.any?
      Campaign.with_brands(params[:brand]).where(id: campaign_ids).pluck(:id)
    else
      Campaign.with_brands(params[:brand]).pluck(:id)
    end
  end
end
