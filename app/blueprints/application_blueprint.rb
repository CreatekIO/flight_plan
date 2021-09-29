class ApplicationBlueprint < Blueprinter::Base
  class LowerCamelTransformer < Blueprinter::Transformer
    def transform(hash, _object, _options)
      hash.transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
    end
  end

  identifier :id

  # transform LowerCamelTransformer

  def self.association_ids(*names)
    names.each { |association| association_id(association) }
  end

  def self.association_id(association, name: nil)
    attribute = AssociationIdsQuery.attribute_for(association)

    field(
      name || association,
      if: -> (_, record, _) { record.has_attribute?(attribute) }
    ) { |record| record[attribute] }
  end

  def self.helpers
    @helpers ||= ActionView::Base.new
  end
end
