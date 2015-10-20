class AddFormFieldResultsUniqueIndex < ActiveRecord::Migration
  def change
    add_index :form_field_results, [:form_field_id, :resultable_id, :resultable_type], unique: true, name: 'idx_ff_res_on_form_field_id_n_resultable_id_n_resultable_type'
  end
end
