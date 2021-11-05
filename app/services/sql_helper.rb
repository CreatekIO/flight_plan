module SQLHelper
  extend ActiveSupport::Concern

  included do
    include HelperMethods
    protected(*HelperMethods.instance_methods)
  end

  module HelperMethods
    # Intention-revealing alias for usage with `alias` and `[]`
    def sql
      SQLHelper
    end

    def alias(expr, as:)
      Arel::Nodes::As.new(expr, literal(as))
    end

    def node(type, *args)
      as_class = type.to_s.classify
      return unless Arel::Nodes.const_defined?(as_class)

      Arel::Nodes.const_get(as_class).new(*args)
    end

    %w[
      true
      false
      window
    ].each do |name|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{name}(*args)
          node(:#{name}, *args)
        end
      RUBY
    end

    def fn(name, *args)
      Arel::Nodes::NamedFunction.new(name.to_s, args)
    end

    %w[
      coalesce
      dense_rank
      first_value
      to_char
    ].each do |name|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{name}(*args)
          fn('#{name}', *args)
        end
      RUBY
    end

    def table(name_or_class)
      name_or_class.try(:arel_table) || Arel::Table.new(name_or_class)
    end

    def [](table_name, column = nil)
      arel_table = table(table_name)
      return arel_table if column.blank?

      case column
      when '*', :*, 'star', :star
        arel_table[Arel.star]
      else
        arel_table[column]
      end
    end

    def select(*projections)
      Arel::SelectManager.new.project(*projections)
    end

    def infinity
      quote(:Infinity)
    end

    def between(expr, from:, to:)
      node(:between, expr, node(:and, [from, to]))
    end

    def count(str, as: nil)
      literal(str).count.tap do |count|
        return count.as(as) if as.present?
      end
    end

    def quote(value)
      Arel::Nodes.build_quoted(value)
    end

    def literal(text)
      Arel.sql(text.to_s)
    end

    def cast(value, as:)
      fn(:CAST, self.alias(value, as: literal(as)))
    end

    def cast_date(value)
      cast(quote(value.to_date), as: :date)
    end

    def date_series(start, finish = nil, step: 1.day)
      if start.is_a?(Range) && finish.nil?
        start = start.begin
        finish = start.end
      end

      casted_interval = step.parts.map do |(name, value)|
        "#{value} #{value == 1 ? name.to_s.singularize : name}"
      end.join(' ')

      fn(:generate_series, cast_date(start), cast_date(finish), quote(casted_interval))
    end
  end

  extend HelperMethods
end
