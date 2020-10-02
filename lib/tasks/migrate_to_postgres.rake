task migrate_to_postgres: :environment do
  ApplicationMigrator.import_all
end
