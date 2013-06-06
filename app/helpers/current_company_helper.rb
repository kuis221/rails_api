module CurrentCompanyHelper

  def company_users
    current_company.users
  end

  def company_roles
    current_company.roles
  end

  def company_teams
    current_company.teams
  end

  def company_campaigns
    current_company.campaigns
  end

  def current_company
    @current_company ||= current_user.try(:company)
  end
end