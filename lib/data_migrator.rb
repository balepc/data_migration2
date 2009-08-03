module ActiveRecord
  class DataMigrator
    TABLE_NAME = 'schema_datas'
    
    def self.initialize_schema_information
      begin
        ActiveRecord::Base.connection.execute "CREATE TABLE #{TABLE_NAME} (version VARCHAR(40))"
      rescue ActiveRecord::StatementInvalid
        # Schema has been initialized
      end
    end

    def migrate(path)
      iterate_files(path) do |version,clazz|
        unless migrated?(version)
          puts 'Migrating'
          puts "#{version} #{clazz} ==============================="
          ActiveRecord::Base.transaction do
            clazz.up
            version_migrated!(version)
          end
        end
      end
    end

    def migrate_back(path)
      iterate_files(path) do |version,clazz|
        if last?(version)
          ActiveRecord::Base.transaction do
            clazz.down
            version_reverted!(version)
          end
        end
      end
    end

    def migrate_redo(path)
      migrate_back(path)
      migrate(path)
    end

    private
    def is_valid_migration_filename?(filename)
      filename =~ /[0-9]+_[a-zA-Z_]+\.rb/
    end
    def extract_name_and_version(filename)
      match = filename.match(/([0-9]+)_(.+)\./)
      return match[1], match[2]
    end
    def version_migrated!(version)
      ActiveRecord::Base.connection.execute("INSERT INTO #{TABLE_NAME} (version) VALUES ('#{version}')")
    end
    def version_reverted!(version)
      ActiveRecord::Base.connection.execute("DELETE FROM #{TABLE_NAME} WHERE version='#{version}'")
    end
    def migrated?(version)
      result = versions.include?(version)
      @versions = nil
      result
    end
    def versions
      return @versions if @versions
      rows = []
      ActiveRecord::Base.connection.execute("SELECT version FROM #{TABLE_NAME} ORDER BY version ASC").each{|row| rows << row[0]}
      @versions = rows
    end
    def last?(version)
      versions.to_a.last?(version)
    end
    def iterate_files(path)
      Dir.entries(File.join(RAILS_ROOT, path)).sort.each do |filename|
        if is_valid_migration_filename?(filename)
          version, name = extract_name_and_version(filename)
          require File.join(RAILS_ROOT, "db/migrate/data/#{filename}")
          clazz = Object.const_get(name.underscore.camelize)
          yield(version, clazz)
        end
      end
    end
  end
end

ActiveRecord::DataMigrator.initialize_schema_information
