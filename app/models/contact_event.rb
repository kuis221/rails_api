# == Schema Information
#
# Table name: contact_events
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  contactable_id   :integer
#  contactable_type :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class ContactEvent < ActiveRecord::Base
  belongs_to :contactable, polymorphic: true
  belongs_to :event

  delegate :company_id, to: :event

  accepts_nested_attributes_for :contactable

  validates :event_id, uniqueness: { scope: [:contactable_type, :contactable_id] }

  delegate :full_name, :country_name, :street_address, :city, :company_id, :country, :email, :first_name, :last_name, :phone_number, :state, :zip_code, to: :contactable

  def title
    contactable.respond_to?(:title) ? contactable.title : contactable.role_name
  end

  def build_contactable(params = {}, assignment_options = {})
    self.contactable = Contact.new(params, assignment_options)
  end

  def self.contactables_for_event(event, term = nil)
    search = Sunspot.search([CompanyUser, Contact]) do
      keywords term do
        fields :name
      end

      all_of do # Exclude users and contacts assigned to the event
        any_of do
          with :class, CompanyUser
          without(:id, event.contact_events.where(contactable_type: 'Contact').select('contactable_id').map(&:contactable_id) + [0])
        end
        any_of do
          with :class, Contact
          without(:id, event.contact_events.where(contactable_type: 'CompanyUser').select('contactable_id').map(&:contactable_id) + [0])
        end
      end
      paginate page: 1, per_page: 10
      with :company_id, event.company_id
      with :status, ['Active']
      order_by :name, :asc
    end
    search.results
  end

  def self.contactables_list(company)
    company.contacts + company.company_users.active.joins([:user, :role]).includes([:user, :role])
  end
end
