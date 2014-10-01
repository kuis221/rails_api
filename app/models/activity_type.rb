# == Schema Information
#
# Table name: activity_types
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  active      :boolean          default(TRUE)
#  company_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ActivityType < ActiveRecord::Base
  belongs_to :company
  scoped_to_company
  has_many :form_fields, -> { order 'form_fields.ordering ASC' }, as: :fieldable
  has_many :companies, through: :activity_type_campaigns

  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  # Campaign relationships
  has_many :activity_type_campaigns
  has_many :campaigns, through: :activity_type_campaigns

  # Goals relationships
  has_many :goals, dependent: :destroy

  accepts_nested_attributes_for :goals
  accepts_nested_attributes_for :form_fields, allow_destroy: true
  scope :active, -> { where(active: true) }
  attr_accessor :partial_path

  before_save :ensure_user_date_field

  searchable do
    integer :id

    text :name, stored: true

    string :name
    string :status

    boolean :active

    integer :company_id
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def autocomplete
    buckets = autocomplete_buckets(activity_types: [ActivityType])
    render json: buckets.flatten
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets = false)
      solr_search do
        with(:company_id, params[:company_id])
        with(:status, params[:status]) if params.key?(:status) && params[:status].present?
        if params.key?(:q) && params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'activity_type'
            with :id, value
          end
        end

        if include_facets
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end

    def report_fields
      {
        name:        { title: 'Activity Type Name' },
        description: { title: 'Activity Type Description' },
        user:        { title: 'Activity User', column: -> { "activity_user.first_name || ' ' || activity_user.last_name" } },
        date:        { title: 'Activity Date', column: -> { "to_char(activities.activity_date, 'YYYY/MM/DD')" } }
      }
    end
  end

  private

  def ensure_user_date_field
    if form_fields.empty? || !form_fields.map(&:type).include?('FormField::UserDate')
      form_fields << FormField::UserDate.new(name: 'User/Date', ordering: (form_fields.map(&:ordering).max || 0) + 1)
    end
  end
end
