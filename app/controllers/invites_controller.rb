class InvitesController < InheritedResources::Base
  belongs_to :event, :venue

  respond_to :js, only: [:new, :create, :edit, :update]

  actions :new, :create, :edit, :update

  protected

  def invite_params
    params.require(:invite).permit(:place_reference, :invitees)
  end
end
