require 'active_support/concern'

module DeactivableController
  extend ActiveSupport::Concern

  def deactivate
    resource.deactivate! if resource.active == true
  end

  def activate
    resource.activate! unless resource.active == true
    render 'deactivate'
  end
end
