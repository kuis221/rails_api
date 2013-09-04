class UpdateKpisAttributes < ActiveRecord::Migration
  def up
    Kpi.find_by_name_and_module('Expenses', 'expenses').update_attribute(:capture_mechanism, 'currency')
    Kpi.find_by_name_and_module('Surveys', 'surveys').update_attribute(:capture_mechanism, 'integer')
  end

  def down
  end
end
