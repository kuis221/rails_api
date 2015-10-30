module Resultable
  extend ActiveSupport::Concern

  included do

    has_many :results, as: :resultable, dependent: :destroy,
                       class_name: 'FormFieldResult', inverse_of: :resultable do
      def active
        where(form_field_id: proxy_association.owner.form_fields)
      end
    end

    accepts_nested_attributes_for :results, allow_destroy: true

    scope :with_results_for, ->(fields) {
      select("DISTINCT #{table_name}.*")
      .joins(:results)
      .where(form_field_results: { form_field_id: fields })
      .where('form_field_results.value is not NULL AND form_field_results.value !=\'\'')
    }

    if column_names.include?('results_version')
      before_save :increment_version_number, if: :results_changed?
    end
  end

  def results_for(fields)
    fields.map do |field|
      result = results.find { |r| r.form_field_id == field.id } || results.build(form_field_id: field.id)
      result.form_field = field # Assign it so it won't be reloaded if requested.
      result
    end
  end

  def result_for_kpi(kpi)
    field = form_fields.find { |f| f.kpi_id == kpi.id }
    return unless field.present?
    field.kpi = kpi # Assign it so it won't be reloaded if requested.
    results_for([field]).first
  end

  def results_for_kpis(kpis)
    kpis.map { |kpi| result_for_kpi(kpi) }.flatten.compact
  end

  def form_field_results
    form_fields.map do |field|
      result = results.find { |r| r.form_field_id == field.id } || results.build(form_field_id: field.id)
      result.form_field = field
      result
    end
  end

  def increment_version_number
    self.results_version += 1
  end

  def results_changed?
    results.any?(&:changed?)
  end
end
