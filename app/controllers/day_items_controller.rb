class DayItemsController < FilteredController
  belongs_to :day_part
  respond_to :js, only: [:new, :create, :edit, :update, :destroy]

  authorize_resource

  protected
    def collection_to_json
      collection.map{|time| {
        :id => time.id,
        :name => time.label,
        :links => {
            delete: day_part_day_item_path(parent, time)
        }
      }}
    end

    def sort_options
      {
        'name' => { :order => 'day_items.start_time' }
      }
    end
end
