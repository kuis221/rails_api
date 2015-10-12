# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  commentable_id   :integer
#  commentable_type :string(255)
#  content          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe Comment, type: :model do
  it { is_expected.to belong_to(:commentable) }

  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:commentable_id) }
  it { is_expected.to validate_numericality_of(:commentable_id) }
  it { is_expected.to validate_presence_of(:commentable_type) }

  describe 'max_event_comments validation' do
    let(:campaign) { create(:campaign) }
    let(:event) { create(:event, campaign: campaign) }

    describe 'when a max is set for the campaign' do
      before do
        event.campaign.update_attribute(
          :modules, 'comments' => { 'settings' => { 'range_min' => '1',
                                                    'range_max' => '2' } })
      end

      it 'should not allow create more than two comments for the event' do
        create_list(:comment, 2, commentable: event)
        comment = build(:comment, commentable: event)
        expect(comment.save).to be_falsey
        expect(comment.errors.full_messages).to include(
          'Oops. No more than 2 comments can be added to this event. Your comment was not saved.')
      end

      it 'correctly displays a message when max is set to 1' do
        event.campaign.update_attribute(
          :modules, 'comments' => { 'settings' => { 'range_max' => '1' } })
        create(:comment, commentable: event)
        comment = build(:comment, commentable: event)
        expect(comment.save).to be_falsey
        expect(comment.errors.full_messages).to include(
          'Oops. No more than one comment can be added to this event. Your comment was not saved.')
      end
    end

    describe 'when a max is not set for the campaing' do
      before do
        event.campaign.update_attribute(
          :modules, 'comments' => { 'settings' => { 'range_min' => '1',
                                                    'range_max' => '' } })
      end

      it 'should not allow create any number of comments for the event' do
        comment = build(:comment, commentable: event)
        expect(comment.save).to be_truthy
      end
    end

    describe 'for_task?' do
      let(:task) { create(:task) }
      let(:event) { create(:event) }

      it 'returns true if comment is for a task' do
        comment = create :comment, commentable: task
        expect(comment.for_task?).to be_truthy
      end

      it 'returns true if comment is for a event' do
        comment = create :comment, commentable: event
        expect(comment.for_task?).to be_falsey
      end
    end
  end
end
