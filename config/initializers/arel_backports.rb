# Adapted from https://github.com/rails/arel/pull/481/files
# Merged into Arel v9 (which is used by Rails v5.2)
raise 'This backport probably not needed' if Arel::SelectManager.instance_methods.include?(:lateral)

class ArelBackPortLateral < Arel::Nodes::Unary; end

Arel::SelectManager.class_eval do
  def lateral(table_name = nil)
    base = table_name.nil? ? ast : as(table_name)
    ArelBackPortLateral.new(base)
  end
end

Arel::Visitors::DepthFirst.class_eval do
  alias_method :visit_ArelBackPortLateral, :unary
end

Arel::Visitors::PostgreSQL.class_eval do
  def visit_ArelBackPortLateral(object, collector) # rubocop:disable Naming/MethodName
    collector << 'LATERAL'
    collector << self.class::SPACE

    if object.expr.is_a?(Arel::Nodes::SelectStatement)
      collector << '('
      visit(object.expr, collector)
      collector << ')'
    else
      visit(object.expr, collector)
    end
  end
end
