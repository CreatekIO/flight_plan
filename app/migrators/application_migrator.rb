class ApplicationMigrator
  class MySQLExport < ActiveRecord::Base
    establish_connection :"#{Rails.env}_mysql"

    self.abstract_class = true

    def self.with_connection(&block)
      connection_pool.with_connection(&block)
    end
  end

  class PostgresImport < ActiveRecord::Base
    establish_connection Rails.env.to_sym

    self.abstract_class = true

    def self.without_triggers
      connection.execute(%[ALTER TABLE "#{table_name}" DISABLE TRIGGER ALL])
      yield
    ensure
      connection.execute(%[ALTER TABLE "#{table_name}" ENABLE TRIGGER ALL])
    end

    def self.import(collection)
      without_triggers { super(collection, validate: false) }
    end

    def self.with_connection(&block)
      connection_pool.with_connection(&block)
    end
  end

  class ActiveRecordInternalMetadata < PostgresImport
    self.table_name = 'ar_internal_metadata'

    def self.set(attrs)
      attrs.each do |key, value|
        where(key: key.to_s).update_all(value: value.to_s)
      end
    end
  end

  class_attribute :logger, :key_mappings, instance_writer: false

  self.logger = ActiveSupport::TaggedLogging.new(
    ActiveSupport::Logger.new($stdout)
  )

  class << self
    include ActiveSupport::Benchmarkable

    attr_reader :models

    def for(klass)
      name = "#{klass}Migrator"

      name.safe_constantize || Object.const_set(name, Class.new(self))
    end

    def inherited(klass)
      super

      klass.key_mappings = HashWithIndifferentAccess.new

      @models ||= []
      @models << klass
    end

    def logger_tag
      base_class.name
    end

    def import_all
      benchmark('Import all') do
        models.each do |model|
          logger.tagged(model.logger_tag) do
            benchmark('Processing') do
              model.import
              model.reset_pk_sequence!
            end
          end
        end

        ActiveRecordInternalMetadata.set(environment: 'production')
      end
    end

    def import
      export do |to_import|
        logger.debug("Using columns: #{to_import.first.keys.join(', ')}")

        benchmark("Importing #{to_import.size} records") do
          postgres_class.import(to_import)
        end
      end
    end

    def reset_pk_sequence!
      postgres_class.connection_pool.with_connection do |connection|
        connection.reset_pk_sequence!(postgres_class.table_name)
      end
    end

    private

    def base_class
      @base_class ||= name.remove(/Migrator$/).constantize
    end

    def mysql_class
      @mysql_class ||= begin
        const_set(:MySQLModel, Class.new(MySQLExport)).tap do |klass|
          klass.table_name = base_class.table_name
          klass.logger = logger if ENV['MIGRATE_LOGGER'].present?
        end
      end
    end

    def postgres_class
      @postgres_class ||= begin
        const_set(:PostgresModel, Class.new(PostgresImport)).tap do |klass|
          klass.table_name = base_class.table_name
          klass.logger = logger if ENV['MIGRATE_LOGGER'].present?
        end
      end
    end

    def ignore_columns(*names)
      mysql_class.ignored_columns = names
    end

    def rename(from, to:)
      key_mappings[from] = to
    end

    def export
      mysql_class.in_batches.each do |relation|
        to_import = benchmark('Exporting') do
          mysql_class.with_connection do |connection|
            connection.select_all(relation.to_sql).map do |attrs|
              attrs.transform_keys { |key| (key_mappings[key] || key).to_s }
            end
          end
        end

        yield(to_import)
      end
    end
  end
end

# Eager-load all migrator classes
%w[
  DataMigration
  BoardRepo
  BoardTicket
  Board
  BranchHead
  Comment
  Labelling
  CommitStatus
  PullRequestConnection
  Milestone
  Release
  PullRequestReview
  RepoReleaseBoardTicket
  PullRequest
  SwimlaneTransition
  Swimlane
  User
  Repo
  Branch
  Label
  Ticket
  RepoRelease
  TicketAssignment
  Timesheet
].each { |klass| ApplicationMigrator.for(klass) }
