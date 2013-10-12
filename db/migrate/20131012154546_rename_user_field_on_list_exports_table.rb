class RenameUserFieldOnListExportsTable < ActiveRecord::Migration
  def up
    rename_column :list_exports, :user_id, :company_user_id
  end

  def down
  end
end
