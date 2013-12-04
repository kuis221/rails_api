require "company_scoped/version"
require 'active_record'
require 'company_scoped/callback'
require 'company_scoped/railtie'

module CompanyScoped
  def scoped_to_company(options = {})
    before_validation CompanyScoped::Callback.new


    belongs_to :company

    def self.ignoring_company_scoped?
      @_ignore_nil ||= false
      @_ignore_nil
    end

    private
      def without_company_scoped
        @_ignore_nil = true
        yield
        @_ignore_nil = false
      end

  end
end
