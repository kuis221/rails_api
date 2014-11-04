# == Schema Information
#
# Table name: filter_settings
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  apply_to        :string(255)
#  settings        :text
#  created_at      :datetime
#  updated_at      :datetime
#

class FilterSetting < ActiveRecord::Base
  belongs_to :company_user

  serialize :settings

  after_initialize :set_default_settings

  # Parse the settings for the file
  SETTINGS = YAML.load_file(File.join(Rails.root, 'config', 'filter_settings.yml')).tap do |settings|
    settings.each do |k, v|
      v.each_with_index do |model, i|
        if model.is_a?(String)
          v[i] = { 'class' => model.constantize,
                   'label' => model.constantize.model_name.human.pluralize }
        else
          model['class'] = model['class'].constantize
        end
      end
    end
  end

  # Required fields
  validates :company_user_id, presence: true, numericality: true
  validates :apply_to, presence: true

  # Returns an array of the chosen settings for a given model if any, or nil
  # if the user haven't entered settings for it. Empty Array means that the user
  # have disabled both Active and Inactive elements.
  # Returns examples:
  #   [true, false]   => when user have selected active and inactive items
  #   [false]         => when user have selected only inactive items
  #   [true]          => when user have selected only active items
  #   []              => when user have deselected both options
  #   nil             => when there are no settings
  def filter_settings_for(klass, format: :boolean)
    return if settings.nil? || !FilterSetting::SETTINGS.key?(apply_to)

    setting = FilterSetting::SETTINGS[apply_to].find { |s| s['class'] == klass }

    return unless setting.present? && settings.include?(setting_key(setting, 'present'))

    status = []
    status.push(format == :string ? 'active' : true) if settings.include?(setting_key(setting, 'active'))
    status.push(format == :string ? 'inactive' : false) if settings.include?(setting_key(setting, 'inactive'))

    status
  end

  def self.models_for(scope)
    return unless SETTINGS.key?(scope)
    SETTINGS[scope].map { |m| m['class'] }
  end

  def self.labels_for(scope)
    return unless SETTINGS.key?(scope)
    SETTINGS[scope].map { |m| m['label'] }
  end

  def self.setting_key(setting, apply_to, state)
    "#{setting['class'].name.pluralize.underscore}_#{apply_to}_#{state.downcase}"
  end

  def setting_key(setting, state)
    FilterSetting.setting_key(setting, apply_to, state)
  end

  def set_default_settings
    self.settings ||= []
    return if apply_to.nil? || !FilterSetting::SETTINGS.key?(apply_to)
    FilterSetting::SETTINGS[apply_to].each do |setting|
      presence_key = setting_key(setting, 'present')
      next if self.settings.include?(presence_key)

      self.settings.push presence_key
      self.settings.push setting_key(setting, 'active')
    end
  end
end
