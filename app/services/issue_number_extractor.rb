module IssueNumberExtractor
  NUMBER_IN_BRANCH = %r{
    (?<=\#) # non-capturing octothorpe
    \d+     # >= 1 digits
  }x

  NUMBER_IN_BODY = %r{
    connect(?:s|ed)? # matches "connect", "connects", "connected"
    (?:
     \p{Blank}       # space or tab
     to
    )?               # matches all of the above permutations with optional "to"
    \p{Blank}        # space or tab
    (
     [a-z0-9\-]+     # user/org name...
     /
     [a-z0-9\-_]+    # ...followed by repo name (similar to username, but allows underscores)...
    )?               # ...which is all optional
    \#
    (\d+)            # issue number
  }ix

  def self.from_branch(branch_name)
    branch_name[NUMBER_IN_BRANCH]
  end

  def self.connections(text, current_repo:)
    text.to_s.scan(NUMBER_IN_BODY).each_with_object(Set.new) do |(slug, number), set|
      slug ||= current_repo.slug

      set.add(repo: slug, number: number)
    end
  end
end
