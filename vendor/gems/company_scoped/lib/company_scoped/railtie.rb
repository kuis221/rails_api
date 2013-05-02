require 'company_scoped'
require 'rails/railtie'

module CompanyScoped
  class Railtie < Rails::Railtie
    initializer 'company_scoped.ar_extensions' do |app|
      ActiveRecord::Base.extend CompanyScoped
    end
  end
end