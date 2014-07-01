class AddIndexesToFormFieldResultsTable < ActiveRecord::Migration
  def change
    add_index :form_field_results, [:resultable_id, :resultable_type]
    add_index :form_field_results, [:resultable_id, :resultable_type, :form_field_id], name: 'index_ff_results_on_resultable_and_form_field_id'
  end
end
