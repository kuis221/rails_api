namespace :kbmg do
  desc 'Sync all KBMG events'
  task synch: :environment do
    KbmgSyncher.synch
  end
end
