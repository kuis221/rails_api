# == Schema Information
#
# Table name: metrics
#
#  id          :integer          not null, primary key
#  type        :string(32)
#  brand_id    :integer
#  program_id  :integer
#  name        :string(255)
#  style       :string(255)
#  optional_id :integer
#  active      :boolean          default(TRUE)
#  creator_id  :integer
#  updater_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#


class Metric < Legacy::Record
  belongs_to    :program

  has_many :metric_results

  scope :system, lambda {where(:program_id => nil, :brand_id => nil)}

  scope :for_program, lambda { |program| {:conditions => ['metrics.program_id = ?', program.id]}}

  has_many :data_migrations, as: :remote, class_name: 'Legacy::DataMigration'

  def synchronize(company, campaign, attributes={})
    if is_kpi?
      migration = data_migrations.find_or_initialize_by_company_id(company.id)
      if migration.local.nil?
        kpi = ::Kpi.where(company_id: company.id).where("trim(both ' ' from lower(regexp_replace(name, '[:#\\.,;]', '','g')))=?", name.gsub(/[:#\.,;]/,'').strip.downcase).first

        # If the KPI wasn't found by the name, try to find a field on the campaign with that label
        if kpi.nil?
          kpi = campaign.form_fields.detect{|f| f.name.gsub(/[:#\.,;]/,'').strip.downcase ==  name.gsub(/[:#\.,;]/,'').strip.downcase && f.field_type == map_type}.try(:kpi)
        end
        kpi ||= ::Kpi.new(company_id: company.id, name: name)
        migration.local = kpi
      end
      #raise "Conflicting KPI found for metric #{self.name}[#{self.id}]: #{kpi.inspect}" if migration.local.persisted? && migration.new_record?
      attributes.merge!({company_id: company.id}).merge!(kpi_migration_attributes(migration.local))
      migration.local.assign_attributes(attributes, without_protection: true)
    else
      migration = data_migrations.find_or_initialize_by_company_id(company.id, local: ::CampaignFormField.find_or_initialize_by_name_and_campaign_id(name, campaign.id) )
      attributes.merge!({campaign_id: campaign.id}).merge!(field_migration_attributes(campaign))
      migration.local.assign_attributes(attributes, without_protection: true)
    end

    migration.save
    migration
  end

  def build_local
    if map_type
      ::Kpi.find_or_initialize_by_name_and_company_id(name, company.id)
    else
      ::CampaignFormField.find_or_initialize_by_name_and_company_id(name, company.id)
    end
  end

  def kpi_migration_attributes(kpi)
    attributes = {
      kpi_type: map_type,
      capture_mechanism:  map_capture_mechanism,
      module: 'custom',
      created_at: created_at,
      updated_at: updated_at
    }

    if respond_to?(:metric_options) and metric_options.any?
      attributes.merge!({kpis_segments_attributes: metric_options.map{|o| { id: (kpi.new_record? ? nil : kpi.kpis_segments.find_by_text(o.name).try(:id)) , text: o.name} } })
    elsif type == 'Metric::Boolean' and kpi.new_record?
      attributes.merge!({kpis_segments_attributes: [
        { id: nil, text: 'Yes'},
        { id: nil, text: 'No'}
      ]})
    end
    attributes
  end

  def field_migration_attributes(campaign)
    ordering = campaign.form_fields.select('max(ordering) as ordering').reorder(nil).first.ordering || 0
    attributes = {
      kpi_id: nil,
      ordering: ordering,
      field_type: map_type,
      options: {capture_mechanism:  map_capture_mechanism},
      section_id: nil,
      created_at: created_at,
      updated_at: updated_at
    }
    attributes
  end

  def is_kpi?
    !['Metric::Paragraph', 'Metric::Sentence'].include?(type)
  end


  def map_type
    case type
    when 'Metric::Multivalue', 'Metric::Boolean', 'Metric::Multi', 'Metric::Select'
      'count'
    when 'Metric::Pie'
      'percentage'
    when 'Metric::BarSpend', 'Metric::PromoHours'
      nil
    when 'Metric::Sentence'
      'text'
    when 'Metric::Paragraph'
      'textarea'
    else
      'number'
    end
  end

  def map_capture_mechanism
    case type
    when 'Metric::Multivalue', 'Metric::Multi', 'Metric::Select'
      case style
        when 'check_boxes' then 'checkbox'
        when 'radio' then 'radio'
        else 'select'
      end
    when 'Metric::Boolean'
      'radio'
    when 'Metric::Pie'
      'decimal'
    when 'Metric::BarSpend', 'Metric::PromoHours', 'Metric::Paragraph', 'Metric::Sentence'
      nil
    when 'Metric::Decimal'
      'decimal'
    when 'Metric::Money'
      'currency'
    else
      'integer'
    end
  end

  def result_hash(result)
    {name => cast_value(result.value)}
  end

  def cast_value(value)
    value
  end

  def fetch_result(result)
    cast_value result.scalar_value
  end

  # convert keys in hash to int to keep things matching up - but preserve values
  # TODO dry vs metrics_helper.rb
  def self.scrub_hash_keys(hash)
    (hash || {}).inject({}) { |h, (k, v)| h[k.to_i] = v; h}
  end
end