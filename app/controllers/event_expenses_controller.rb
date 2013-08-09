class EventExpensesController < InheritedResources::Base
  respond_to :js

  belongs_to :event
end
