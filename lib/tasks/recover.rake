require 'csv'

namespace :remote do
  task fix: :environment do
    def remote_field_for(kpi, campaign_id)
      @fields ||= {}
      @fields[kpi.id] ||= {}
      @fields[kpi.id][campaign_id] ||= Remote::CampaignFormField.where(campaign_id: campaign_id, kpi_id: kpi.id).first
      @fields[kpi.id][campaign_id]
    end

    def campaigns_for_kpi(kpi)
      @campaigns ||= {}
      @campaigns[kpi.id] ||= Campaign.find(CampaignFormField.where(kpi_id: kpi).select('DISTINCT(campaign_id) as campaign_id').map(&:campaign_id))
      @campaigns[kpi.id]
    end

    def copy_results(kpi_from, kpi_to, remote_kpi, csv)
      campaigns = campaigns_for_kpi(kpi_from)
      remote_results = Hash[Remote::EventResult.where(kpi_id: kpi_to.id).map { |r| [r.event_id, r] }]
      puts "   Recovering results from #{kpi_from.name} into #{kpi_to.name} in campaigns: #{campaigns.map(&:name)}"
      EventResult.joins(:event).select('event_results.*, events.campaign_id').where(events: { campaign_id: campaigns }, kpi_id: kpi_from.id).where('event_results.value is not null and event_results.value != \'\'').find_each do |result|
        remote_result = remote_results.try(:[], result.event_id)
        puts "  [#{result.event_id}]:: remote[#{remote_result.try(:id)}]: '#{remote_result.try(:value)}' <<==>> '#{result.value}'"
        if remote_result.nil? || (remote_result.value_is_empty? && remote_result.value.to_s != result.value.to_s)
          value = text = result.value
          if kpi_from.kpi_type == 'count'
            if value.is_a?(Array)
              text = kpi_from.kpis_segments.select { |s| value.include?(s.id) }.map(&:text)
              value = kpi_to.kpis_segments.select { |s| text.include?(s.text) }.map(&:id).join(',')
              text = text.to_sentence
            else
              text = kpi_from.kpis_segments.find { |s| s.id == result.value.to_i }.try(:text)
              value = kpi_to.kpis_segments.find { |s| s.text == text }.try(:id)
            end
          end
          if remote_result.nil?
            field = remote_field_for(remote_kpi, result.campaign_id)
            remote_result = Remote::EventResult.new(kpi_id: remote_kpi.id, form_field_id: field.try(:id), event_id: result.event_id)
          end
          remote_result.scalar_value = value.try(:to_f) unless kpi_from.kpi_type == 'count'
          remote_result.value = value
          remote_result.save
          # puts "  Found missing result for event #{result.event_id}: #{value}"
          csv << [kpi_from.name, remote_kpi.name, "http://stage.brandscopic.com/events/#{result.event_id}", remote_result.try(:value), text, value]
        end
      end
    end
    require 'remote'
    CSV.open('tmp/restored_results.csv', 'wb') do |csv|
      csv << ['Source KPI', 'Target KPI', 'Event', 'Value Before', 'Value After']
      CSV.foreach('tmp/kpi_recover2.csv', headers: true) do |row|
        puts "Processing: '#{row['kpi1']}' :: '#{row['kpi2']}'"
        local_kpi1 = Kpi.where(name: row['kpi1']).first
        local_kpi2 = Kpi.where(name: row['kpi2']).first
        if local_kpi1 && local_kpi2
          remote_kpi1 = Remote::Kpi.where(id: local_kpi1.id).first
          remote_kpi2 = Remote::Kpi.where(id: local_kpi2.id).first
          if remote_kpi1 && remote_kpi2
            puts "  KPI: '#{row['kpi1']}' & '#{row['kpi2']}' exists on remote DB: IGNORING"
          elsif remote_kpi1 || remote_kpi2
            # if the KPI1 was kept, then try to copy all the results for the kpi2
            # into all the events
            if remote_kpi1.present?
              copy_results(local_kpi2, local_kpi1, remote_kpi1, csv)
            end
            if remote_kpi2.present?
              copy_results(local_kpi1, local_kpi2, remote_kpi2, csv)
            end
          else
            puts " KPI: '#{row['kpi1']}' && '#{row['kpi2']}' doesn't exists in remote DB"
          end
        else
          puts "  KPI: '#{row['kpi1']}' doesn't exists on local DB" if local_kpi1.nil?
          puts "  KPI: '#{row['kpi2']}' doesn't exists on local DB" if local_kpi2.nil?
        end
      end
    end
  end
end
