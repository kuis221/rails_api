# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  message         :string(255)
#  level           :string(255)
#  path            :text
#  icon            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  message_params  :text
#  extra_params    :text
#  params          :hstore
#

require 'rails_helper'

describe Notification, type: :model do
  it { is_expected.to belong_to(:company_user) }

  describe 'send_late_event_sms_notifications' do
    let(:user) do
      create(:company_user, company: create(:company),
                                        user: create(:user, phone_number: '+15558888888'),
                                        notifications_settings: %w(event_recap_late_sms event_recap_due_sms))
    end
    let(:campaign) { create(:campaign, company: user.company) }

    before { user.user.update_attribute :phone_number_verified, true }

    it 'should not call enqueue any SendSmsWorker' do
      event = create(:event, campaign: campaign)

      expect(Resque).not_to receive(:enqueue)
      Notification.send_late_event_sms_notifications
    end

    it 'should not call enqueue with the correct message if the user have one late but not due event recaps' do
      event = create(:late_event, campaign: campaign)
      event.users << user
      expect(Resque).to receive(:enqueue).with(SendSmsWorker, '+15558888888', 'You have one late event recap')
      Notification.send_late_event_sms_notifications
    end

    it 'should not call enqueue with the correct message if the user have one due but not late event recaps' do
      event = create(:due_event, campaign: campaign)
      event.users << user
      expect(Resque).to receive(:enqueue).with(SendSmsWorker, '+15558888888', 'You have one due event recap')
      Notification.send_late_event_sms_notifications
    end

    it 'should not call enqueue with the correct message if the user have one late and one due event recaps' do
      event = create(:late_event, campaign: campaign)
      event.users << user

      event = create(:due_event, campaign: campaign)
      event.users << user

      expect(Resque).to receive(:enqueue).with(SendSmsWorker, '+15558888888', 'You have 1 due and 1 late event recaps')
      Notification.send_late_event_sms_notifications
    end
  end
end
