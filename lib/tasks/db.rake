namespace :db do
  namespace :functions do
    task load: :environment do
      p "HERE!!! !!!!!!!!!!!!!!!!2222222222"
      functions = File.read(Rails.root.join('db', 'functions.sql'))
      ActiveRecord::Base.connection.execute functions
    end
  end

  namespace :schema do
    task :load do
      p "HERE!!! !!!!!!!!!!!!!!!!"
      Rake::Task['db:functions:load'].invoke
    end
  end

  namespace :test do
    task :load do
      p "HERE!!! !!!!!!!!!!!!!!!!"
      Rake::Task['db:functions:load'].invoke
    end
  end
end
