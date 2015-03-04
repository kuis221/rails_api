class AddTdLinxCodeConfidenceToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :td_linx_confidence, :integer
    execute 'UPDATE places set td_linx_confidence=8 WHERE td_linx_code IS NOT NULL'
  end
end
