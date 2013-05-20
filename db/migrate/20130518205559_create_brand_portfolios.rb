class CreateBrandPortfolios < ActiveRecord::Migration
  def change
    create_table :brand_portfolios do |t|
      t.string :name
      t.boolean :active
      t.references :company
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
    add_index :brand_portfolios, :company_id

    create_table :brand_portfolios_brands do |t|
      t.references :brand
      t.references :brand_portfolio
    end
    add_index :brand_portfolios_brands, :brand_id
    add_index :brand_portfolios_brands, :brand_portfolio_id
    add_index :brand_portfolios_brands, [:brand_id, :brand_portfolio_id], name: :brand_portfolio_unique_idx, unique: true

  end
end
