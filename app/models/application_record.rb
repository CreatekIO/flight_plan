class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.permissive_enum(definitions)
    enum(definitions)

    definitions.each_key do |column|
      attribute_types[column.to_s].extend(AllowValuesInEnum)
    end
  end

  module AllowValuesInEnum
    def deserialize(value)
      super.presence || value
    end

    def assert_valid_value(value)
      super
    rescue ArgumentError => error
      Rails.logger.warn(error.message)
      Bugsnag.notify(error)

      # Return value so that it gets assigned
      value
    end
  end

  def self.with_association_ids(association, &block)
    AssociationIdsQuery.new(all, association, &block).to_relation
  end

  def self.except_columns(*names)
    select(column_names - names.map(&:to_s))
  end

  # For flipper gem
  def flipper_id
    to_gid
  end
end
