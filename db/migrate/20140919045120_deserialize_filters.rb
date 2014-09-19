class DeserializeFilters < ActiveRecord::Migration
  def change
    CustomFilter.find_each do |cf|
      cf.filters
      if cf.filters.match(/\A\-\-\- /)
        cf.update_column(:filters, YAML::load(cf.filters))
      end
    end
  end
end
