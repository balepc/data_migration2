class DataMigrationGenerator < Rails::Generator::NamedBase
  
  def manifest
    record do |m|
       m.migration_template 'data_migration.rb', 'db/migrate/data'
    end
  end

  def file_name
    class_name.underscore
  end

end

