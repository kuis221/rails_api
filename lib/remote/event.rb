module Remote
  class Event < Remote::Record
    belongs_to :campaign, class_name: 'Remote::Campaign'

    has_many :results, class_name: 'Remote::EventResult', inverse_of: :event do
      def active
        where(form_field_id: proxy_association.owner.campaign.form_field_ids)
      end
    end
  end
end
