class EventExpensesController < InheritedResources::Base
  respond_to :js

  belongs_to :event

  load_and_authorize_resource :event
  load_and_authorize_resource
end
