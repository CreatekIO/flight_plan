class DataMigrationMigrator < ApplicationMigrator
  class DataMigration < ActiveRecord::Base; end

  class << self
    def import
      postgres_class.with_connection do |connection|
        break if connection.table_exists?(:data_migrations)

        connection.create_table :data_migrations, id: false do |t|
          t.string :version, null: false
          t.index :version, unique: true
        end
      end

      super
    end

    private

    def base_class
      @base_class ||= DataMigration
    end
  end
end
