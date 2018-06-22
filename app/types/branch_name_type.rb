class BranchNameType < ActiveRecord::Type::String
  BRANCH_REF_PREFIX = %r{^refs/heads/}

  def self.normalize(name)
    name.remove(BRANCH_REF_PREFIX)
  end

  def self.valid_ref?(ref)
    ref.to_s =~ BRANCH_REF_PREFIX
  end

  def cast(value)
    return super if value.nil?

    super(self.class.normalize(value))
  end

  def serialize(value)
    cast(value)
  end
end
