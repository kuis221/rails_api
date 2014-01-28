class CreateTdLinxes < ActiveRecord::Migration
  def change
    create_table :td_linxes do |t|
      t.string :store_code
      t.string :retailer_dba_name
      t.string :retailer_address
      t.string :retailer_city
      t.string :retailer_state
      t.string :retailer_trade_channel
      t.string :license_type
      t.string :fixed_address

      t.timestamps
    end

    add_index :td_linxes, :store_code, unique: true
  end
end
