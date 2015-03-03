# == Schema Information
#
# Table name: metrics
#
#  id          :integer          not null, primary key
#  type        :string(32)
#  brand_id    :integer
#  program_id  :integer
#  name        :string(255)
#  style       :string(255)
#  optional_id :integer
#  active      :boolean          default(TRUE)
#  creator_id  :integer
#  updater_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#

# for storing an inventory item and quantity
# TODO handle missing item.
class Metric::Swag < Metric
  belongs_to :item, foreign_key: :optional_id
  delegate :name, to: :item, prefix: true, allow_nil: true

  def form_options
    super.merge(hint: (item_name), item_inventories: item ? item.inventories : nil)
  end

  def field_type_symbol
    'what?'
  end

  def validate_result(result)
    result.errors.add(:value, 'must be a number') unless value_is_float?(result.value)
    result.errors.add(:value, 'No decimal place allowed') unless result.value.to_i.to_f == result.value.to_f
    result.errors.add(:value, 'Cannot be negative') if cast_value(result.value) < 0
    if result.errors.empty?
      event     = result.event_recap.event
      market    = event.market
      inventory = item.inventories.find_by_market_id(market.id)
      quantity  = inventory ? inventory.quantity : 0
      result.errors.add(:value, "Insufficient stock in #{market.name}") if cast_value(result.value) > quantity
    end
  end

  def approve_result(result)
    event     = result.event_recap.event
    inventory = item.inventories.find_by_market_id(event.market_id)
    if inventory.nil?
      fail Legacy::OutOfStock, "No inventory in #{market.name}" if result.value > 0
    else
      inventory.reduce_quantity(result.value, InventoryChangeReason.distributed, result.event_recap)
    end
  end

  def cast_value(value)
    value.to_i
  end
end
