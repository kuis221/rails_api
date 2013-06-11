class DateItemsController < FilteredController
  belongs_to :date_range
  respond_to :js, only: [:new, :create, :edit, :update]

  authorize_resource

  protected
    def collection_to_json
      collection.map{|date| {
        :id => date.id,
        :name => date.label,
        :links => {
            edit: edit_date_range_date_item_path(parent, date),
            show: date_range_date_item_path(parent, date),
            delete: date_range_date_item_path(parent, date),
        }
      }}
    end

    def sort_options
      {
        'name' => { :order => 'date_items.start_date' }
      }
    end

    def build_resource(*args)
      @date ||= super
      @date.recurrence_type ||= 'daily'
      @date.recurrence_period ||= 1
      @date
    end
end
