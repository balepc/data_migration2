namespace :db do
  namespace :migrate do
    PATH = 'db/migrate/data'
    
    desc "Migrate data"
    task :data => :environment do
      FileUtils.mkdir(PATH) if not File.exists?(PATH)
      ActiveRecord::DataMigrator.new.migrate(PATH)
    end

    namespace :data do
      desc "Remigrate last data"
      task :redo => :environment do
        ActiveRecord::DataMigrator.new.migrate_redo(PATH)
      end

      desc "Step back"
      task :back => :environment do
        ActiveRecord::DataMigrator.new.migrate_back(PATH)
      end
    end
    
  end

end