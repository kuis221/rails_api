class ActivitiesController < InheritedResources::Base
  respond_to :html
  respond_to :json, only: :index


  # Scopes for the calendar view
  has_scope :start, only: [:index] do |controller, scope, value|
    scope.after_date(Time.at(value.to_i).to_datetime)
  end

  has_scope :end, only: [:index] do |controller, scope, value|
    scope.before_date(Time.at(value.to_i).to_datetime)
  end


  protected
    def collection
      @activities ||= end_of_association_chain.order('start_date asc')
    end
end
