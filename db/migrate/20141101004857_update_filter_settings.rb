class UpdateFilterSettings < ActiveRecord::Migration
  def change
    FilterSetting.find_each do |filter_setting|
      next if filter_setting.settings.nil?

      filter_setting.settings.concat(filter_setting.settings.map do |k|
        k.gsub(/_(in)?active\z/, '_present')
      end.uniq)
      filter_setting.settings.uniq!
      filter_setting.save
    end
  end
end
