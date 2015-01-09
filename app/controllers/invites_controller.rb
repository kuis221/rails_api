class InvitesController < InheritedResources::Base
  belongs_to :event, :venue, optional: true

  respond_to :js, only: [:new, :create, :edit, :update]

  actions :new, :create, :edit, :update

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  protected

  def invite_params
    params.require(:invite).permit(:place_reference, :invitees)
  end
end
