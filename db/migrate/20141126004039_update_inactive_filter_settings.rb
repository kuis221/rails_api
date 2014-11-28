class UpdateInactiveFilterSettings < ActiveRecord::Migration
  def change
    FilterSetting.all.each do |fs|
      if fs.settings.any? { |c| c.include?('_active') }
        fs.settings = ['show_inactive_items']
      else
        fs.settings = []
      end
      fs.save
    end
  end
end
