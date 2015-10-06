namespace :kbmg do
  desc 'Sync all KBMG events'
  task synch: :environment do
    KbmgSyncher.new.synch
  end
end
