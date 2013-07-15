class KpisController < FilteredController
  belongs_to :campaign
  respond_to :js, only: [:new, :create]

  def create
    create! do |success, failure|
      success.js do
          parent.kpis << resource if parent? and parent
          render
      end
    end
  end
end