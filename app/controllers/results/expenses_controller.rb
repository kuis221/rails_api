class Results::ExpensesController < FilteredController

  defaults :resource_class => ::Event
  respond_to :xlsx, only: :index

  helper_method :expenses_total

  private
    def search_params
      @search_params ||= begin
        super
        unless @search_params.has_key?(:user) && !@search_params[:user].empty?
          @search_params[:with_event_data_only] = true
        end
        @search_params
      end
    end

    def expenses_total
      search_params[:per_page] = 2000
      search = resource_class.do_search(search_params)
      event_ids = search.hits.map{|h| h.stored(:id)}

      expenses = EventExpense.select('sum(amount) AS total_expenses')
                             .where(["event_id IN (?)", event_ids]).all.first

      expenses.total_expenses || 0
    end

    def authorize_actions
      authorize! :index_results, EventExpense
    end
end