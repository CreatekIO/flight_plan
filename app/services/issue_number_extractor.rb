module IssueNumberExtractor
  NUMBER = /(?<number>[1-9][0-9]*)/
  NUMBER_IN_BRANCH = /##{NUMBER}/

  def self.from_branch(branch_name)
    branch_name[NUMBER_IN_BRANCH, :number]
  end

  CONNECTION = %r{
    connect(s|ed)?
    (\p{Blank}to\b)?
  }ix

  SLUG = %r{(?<slug>[a-z0-9\-]+/[a-z0-9\-_]+)}i
  FULL_URL = %r{https://github\.com/#{SLUG}/issues/#{NUMBER}}i
  SHORTHAND_REFERENCE = /#{SLUG}?##{NUMBER}/

  REFERENCE = %r{
    #{CONNECTION}
    \p{Blank}
    #{Regexp.union(FULL_URL, SHORTHAND_REFERENCE)}
  }x

  def self.connections(text, current_repo:)
    text.to_s.to_enum(:scan, REFERENCE).each_with_object(Set.new) do |_, set|
      match = Regexp.last_match

      set.add(
        number: match[:number],
        repo: match[:slug].presence || current_repo.slug
      )
    end
  end
end
