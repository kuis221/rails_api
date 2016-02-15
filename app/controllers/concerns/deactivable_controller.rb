require 'active_support/concern'

module DeactivableController
  extend ActiveSupport::Concern

  def deactivate
    resource.deactivate! if resource.active == true
    # Change the current_company_id for the disabled company_user if both have the same value
    # This is to avoid the app remembers the company id for the disabled company_user, so signin won't address to the wrong company
    if resource.is_a?(CompanyUser) && resource.user.current_company_id == resource.company_id
      new_cid = resource.user.company_users.active.first.present? ? resource.user.company_users.active.first.company_id : nil
      resource.user.update_column(:current_company_id, new_cid)
    end
  end

  def activate
    resource.activate! unless resource.active == true
    render 'deactivate'
  end
end
