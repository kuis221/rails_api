# == Schema Information
#
# Table name: programs
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  brand_id          :integer
#  events_based      :boolean          default(TRUE)
#  hours_based       :boolean          default(FALSE)
#  managed_bar_night :boolean          default(TRUE)
#  brand_ambassador  :boolean          default(FALSE)
#  active            :boolean          default(TRUE)
#  creator_id        :integer
#  updater_id        :integer
#  created_at        :datetime
#  updated_at        :datetime
#

class Legacy::Program  < Legacy::Record
  has_many      :events
  belongs_to    :brand

  delegate :name, to: :brand, allow_nil: true, prefix: true

  has_many :data_migrations, as: :remote

  def sincronize(company, attributes={})
    attributes.merge!({company_id: company.id})
    migration = data_migrations.find_or_initialize_by_company_id(company.id, local: ::Campaign.new )
    if migration.local.new_record? || migration.local.form_fields.count == 0
      attributes.merge!({form_fields_attributes: form_field_attributes})
    end
    migration.local.assign_attributes(migration_attributes.merge(attributes), without_protection: true)
    migration.save
    migration
  end

  def migration_attributes(attributes={})
    {
      name: name,
      brands_list: brand_name,
      aasm_state: ( active ? 'active' : 'inactive' ),
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def form_field_attributes
    {
      "0" => {"ordering"=>"0", "name"=>"Gender", "field_type"=>"percentage", "kpi_id"=>"5", "options"=>{"capture_mechanism"=>"integer", "predefined_value"=>""}},
      "1" => {"ordering"=>"1", "name"=>"Age", "field_type"=>"percentage", "kpi_id"=>"6", "options"=>{"capture_mechanism"=>"integer", "predefined_value"=>""}},
      "2" => {"ordering"=>"2", "name"=>"Ethnicity/Race", "field_type"=>"percentage", "kpi_id"=>"7", "options"=>{"capture_mechanism"=>"integer", "predefined_value"=>""}},
      "3" => {"ordering"=>"3", "name"=>"Expenses", "field_type"=>"number", "kpi_id"=>"8", "options"=>{"capture_mechanism"=>"", "predefined_value"=>""}},
      "4" => {"ordering"=>"4", "name"=>"Surveys", "field_type"=>"surveys", "kpi_id"=>"11"},
      "5" => {"ordering"=>"5", "name"=>"Photos", "field_type"=>"photos", "kpi_id"=>"9"},
      "6" => {"ordering"=>"6", "name"=>"Videos", "field_type"=>"videos", "kpi_id"=>"10"},
      "7" => {"ordering"=>"7", "name"=>"Impressions", "field_type"=>"number", "kpi_id"=>"2", "options"=>{"capture_mechanism"=>"", "predefined_value"=>""}},
      "8" => {"ordering"=>"8", "name"=>"Interactions", "field_type"=>"number", "kpi_id"=>"3", "options"=>{"capture_mechanism"=>"", "predefined_value"=>""}},
      "9" => {"ordering"=>"9", "name"=>"Samples", "field_type"=>"number", "kpi_id"=>"4", "options"=>{"capture_mechanism"=>"", "predefined_value"=>""}},
      "10"=> {"ordering"=>"10", "name"=>"Your Comment", "field_type"=>"comments"}
    }
  end
end