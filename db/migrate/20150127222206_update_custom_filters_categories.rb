class UpdateCustomFiltersCategories < ActiveRecord::Migration
  def change
    CustomFilter.where(owner_type:'Company').group('"group", owner_id').pluck('DISTINCT "group", owner_id').each {|name, company_id| CustomFiltersCategory.create(company_id: company_id, name: name)  }
  end
end
