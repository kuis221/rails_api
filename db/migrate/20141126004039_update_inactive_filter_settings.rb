class UpdateInactiveFilterSettings < ActiveRecord::Migration
  def change
    FilterSetting.all.each do |fs|
      fs.settings.reject! { |c| c.include?('_active') }
      if fs.settings.reject! { |c| c.include?('_inactive') }
        fs.settings << 'show_inactive_items'
      end
      fs.save
    end
  end
end
