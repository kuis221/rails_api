require 'active_support/concern'

module EventBaseSolrSearchable
  extend ActiveSupport::Concern

  included do
    extend ClassMethods
  end

  module ClassMethods
    def apply_user_permissions_to_search(permission_class, subject_id, permission, company_user)
      proc do
        unless company_user.role.is_admin?
          if company_user.role.permission_for(permission, permission_class, subject: subject_id).mode == 'campaigns'
            with_campaign company_user.accessible_campaign_ids + [0]
          elsif company_user.role.permission_for(permission, permission_class, subject: subject_id).mode == 'none'
            with_campaign [0]
          end
          within_user_locations(company_user)
        end
      end
    end

    def search_start_date_field
      if Company.current && Company.current.timezone_support?
        :local_start_at
      else
        :start_at
      end
    end

    def search_end_date_field
      if Company.current && Company.current.timezone_support?
        :local_end_at
      else
        :end_at
      end
    end
  end
end
