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
#  created_by_id :integer
#  updated_by_id :integer
#

require 'rails_helper'

RSpec.describe Invite, type: :model do
  it { is_expected.to belong_to(:event) }
  it { is_expected.to belong_to(:venue) }
  it { is_expected.to have_one(:place).through(:venue) }
  it { is_expected.to have_many(:individuals) }

  it { is_expected.to validate_presence_of(:event) }
  it { is_expected.to validate_presence_of(:venue) }
  it { is_expected.to validate_presence_of(:invitees) }
  it { is_expected.to validate_numericality_of(:invitees) }

  describe '#activate' do
    let(:invite) { create(:invite, active: false) }

    it 'deactivates the invite' do
      invite.activate!
      invite.reload
      expect(invite.active).to be_truthy
    end
  end

  describe '#deactivate' do
    let(:invite) { create(:invite, active: true) }

    it 'deactivates the invite' do
      invite.deactivate!
      invite.reload
      expect(invite.active).to be_falsey
    end
  end

end
