module CurrentCompanyHelper
  delegate :company_users, to: :current_company

  def company_roles
    current_company.roles
  end

  def company_teams
    current_company.teams
  end

  def company_campaigns
    current_company.campaigns.order('name')
  end

  def current_company
    @current_company ||= current_user.try(:company)
  end

  delegate :current_company_user, to: :current_user
end
