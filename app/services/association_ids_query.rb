class AssociationIdsQuery
  ARRAY_ALIAS = "ids"

  def initialize(scope, association_name, &block)
    @current_scope = scope
    @parent_class = scope.klass
    @association_name = association_name
    @subquery_name = "_#{association_name}"
    @block = block
  end

  def to_relation
    current_scope.joins(
      'CROSS JOIN LATERAL (' \
        "SELECT ARRAY(#{subquery.to_sql}) AS #{ARRAY_ALIAS}" \
      ") #{subquery_name}"
    ).select(*select_values)
  end

  private

  attr_reader :current_scope, :parent_class, :association_name, :subquery_name, :block

  def select_values
    values = [
      Arel::Table.new(subquery_name)[ARRAY_ALIAS].as(
        "preloaded_#{association_name.to_s.singularize}_ids"
      )
    ]

    values.unshift(parent_class.arel_table[Arel.star]) if current_scope.select_values.none?
    values
  end

  # Easiest way to build up a query for an association.
  # We use the id of this record as a placeholder in order to substitute
  # it with the primary key of the parent table in order to produce a
  # correlated subquery
  def placeholder_record
    @placeholder_record ||= parent_class.new(id: -parent_class.hash.abs) do |record|
      record.instance_variable_set(:@new_record, false)
      record.readonly!
    end
  end

  def subquery
    query = placeholder_record.association(association_name).reader
    query = query.instance_exec(&block) if block

    swap_placeholder_for_parent_id_column!(query.arel.ast)

    query.select(:id)
  end

  def swap_placeholder_for_parent_id_column!(ast)
    stack = ast.cores.flat_map(&:wheres)
    parent_id_column = parent_class.arel_table[parent_class.primary_key]

    while node = stack.pop do
      case node
      when Arel::Nodes::And
        stack += node.children
      when Arel::Nodes::Equality
        if substitute_column?(node.right)
          node.right = parent_id_column
          return
        else
          stack << node.left << node.right
        end
      end
    end
  end

  def substitute_column?(node)
    node.is_a?(Arel::Nodes::BindParam) \
      && node.value.value == placeholder_record.id
  end
end
