module Brandscopic
  module ActiveAdminVersionManager
    extend ActiveSupport::Concern

    included do
      before_action :load_resource_version
    end

    def load_resource_version
      return unless params[:version] && params[:id]
      set_resource_ivar resource_class.find(params[:id]).versions[params[:version].to_i-1].reify
    end
  end
end
