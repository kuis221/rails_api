class AddExpenseCategoriesToCompanies < ActiveRecord::Migration
  def up
    add_column :companies, :expense_categories, :text
    Company.find_each do |company|
      if [2, 7].include?(company.id)
        company.expense_categories = "Bar Spend\nTip\nSupplies\nOther"
      end
      company.save # so default expense_categories are assigned
      categories = company.expense_categories.split(/\s*\n\s*/)
      company.campaigns.where('modules like ?', '%expenses%').each do |campaign|
        campaign.modules['expenses']['settings'] ||= {}
        campaign.modules['expenses']['settings'] = campaign.modules['expenses']['settings'].merge(
          'categories' => categories)
        campaign.save
      end
    end
  end

  def down
    remove_column :companies, :expense_categories
  end
end
