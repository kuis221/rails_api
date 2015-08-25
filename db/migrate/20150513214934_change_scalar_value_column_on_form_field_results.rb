class ChangeScalarValueColumnOnFormFieldResults < ActiveRecord::Migration
  def change
    change_column :form_field_results, :scalar_value, :decimal, precision: 15, scale: 2
  end
end
