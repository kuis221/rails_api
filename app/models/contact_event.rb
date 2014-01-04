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

  validates :event_id, :uniqueness => { :scope => [:contactable_type, :contactable_id] }

  delegate :full_name, :country_name, :street_address, :city, :company_id, :country, :email, :first_name, :last_name, :phone_number, :state, :zip_code, to: :contactable

  def title
    contactable.respond_to?(:title) ? contactable.title : contactable.role_name
  end

  def build_contactable(params={}, assignment_options={})
    self.contactable = Contact.new(params, assignment_options)
  end

  def self.contactables_for_event(event)
    (contactables_list(event.company) - event.contacts).sort{|a, b| a.full_name <=> b.full_name}
  end

  def self.contactables_list(company)
    company.contacts+company.company_users.active.joins([:user, :role]).includes([:user, :role])
  end
end
