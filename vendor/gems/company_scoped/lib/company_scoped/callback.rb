module CompanyScoped
  class Callback
    def before_validation(record)
      if record.respond_to?(:company_id) && current_user && record.new_record?
        record.company_id ||= current_company.id unless current_company.nil?
      end
    end

    # relies on `include SentientUser` on User
    def current_user
      logger.warn "WARNING: User#current is not defined, are you including SentientUser on your User model?" unless User.respond_to?(:current)
      logger.warn "WARNING: User#current is nil, are you including SentientController on your ApplicationController?" unless User.current

      User.current
    end

    def current_company
      current_user.current_company
    end

    def logger
      Rails.logger
    end
  end
end