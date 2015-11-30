# == Schema Information
#
# Table name: invites
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  venue_id      :integer
#  market        :string(255)
#  invitees      :integer          default("0")
#  rsvps_count   :integer          default("0")
#  attendees     :integer          default("0")
#  final_date    :date
#  created_at    :datetime
#  updated_at    :datetime
#  active        :boolean          default("true")
#  area_id       :integer
#  created_by_id :integer
#  updated_by_id :integer
#

require 'rails_helper'

RSpec.describe Invite, type: :model do
  it { is_expected.to belong_to(:event) }
  it { is_expected.to belong_to(:venue) }
  it { is_expected.to belong_to(:area) }
  it { is_expected.to have_one(:place).through(:venue) }
  it { is_expected.to have_many(:rsvps) }

  it { is_expected.to validate_presence_of(:event) }
  it { is_expected.to validate_presence_of(:venue) }
  it { is_expected.to validate_presence_of(:invitees) }
  it { is_expected.to validate_numericality_of(:invitees) }
end
