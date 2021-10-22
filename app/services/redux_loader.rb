class ReduxLoader
  class << self
    alias_method :from, :new
  end

  delegate :dig, to: :to_h

  def self.to_key(object)
    name = case object
    when Class, ActiveRecord::Base
      object.model_name.plural
    when String, Symbol
      object.to_s
    end

    name.camelize(:lower)
  end

  def initialize(klass, id, &block)
    queue[klass] << id
    @associations = []
    @queries = []
    @loaded = false
    @serializers = {}
    instance_exec(&block) if block_given?
  end

  def fetch(klass, *named_associations, **scoped_associations)
    query = klass.all

    scoped_associations.merge(
      named_associations.map { |name| [name, nil] }.to_h
    ).each do |name, scope|
      reflection = query.klass.reflect_on_association(name)

      if reflection.collection?
        query = query.with_association_ids(name, &scope)
      end

      @associations << reflection
    end

    @queries << query
  end

  def serialize(specs)
    serializers.merge!(specs)
  end

  def to_h
    load!
    records
  end

  def merge!(relation)
    load!
    add(relation)
  end

  def as_json(*)
    to_h.each_with_object({}) do |(klass, records), json|
      blueprint = "#{klass}Blueprint".safe_constantize || ApplicationBlueprint
      key = self.class.to_key(klass)
      view = serializers[klass]

      json[key] = records.transform_values do |record|
        blueprint.render_as_hash(record, view: view, records: self)
      end
    end
  end

  private

  attr_reader :queries, :associations, :serializers

  def queue
    @queue ||= Hash.new { |hash, key| hash[key] = Set.new }
  end

  def records
    @records ||= Hash.new { |hash, key| hash[key] = {} }
  end

  def loaded?
    @loaded
  end

  def load!
    return if loaded?

    loop do
      next_query = queries.shift
      break unless next_query

      pending_ids = queue[next_query.klass]
      next if pending_ids.none?

      results = next_query.where(id: pending_ids)

      add(results)
      enqueue(results)
    end

    @loaded = true
  end

  def add(results)
    records[results.klass].merge!(results.index_by(&:id))
    queue[results.klass].clear
  end

  def enqueue(results)
    associations.each do |association|
      next unless association.active_record == results.klass

      ids = if association.collection?
        results.flat_map do |record|
          record[AssociationIdsQuery.attribute_for(association.name)]
        end
      else
        results.map(&association.foreign_key.to_sym).compact
      end

      queue[association.klass].merge(ids)
      queries << association.klass.all
    end
  end
end
