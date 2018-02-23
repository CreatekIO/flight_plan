module IssueNumberExtractor
  NUMBER_IN_BRANCH = /
    (?<=\#) # non-capturing octothorpe
    \d+     # >= 1 digits
  /x

  NUMBER_IN_BODY = /
    connect(?:s|ed)? # matches "connect", "connects", "connected"
    (?:
     \p{Blank}       # space or tab
     to
    )?               # matches all of the above permutations with optional "to"
    \p{Blank}        # space or tab
    \#
    (\d+)
  /ix

  def self.from_branch(branch_name)
    branch_name[NUMBER_IN_BRANCH]
  end

  def self.connections(text)
    text.to_s.scan(NUMBER_IN_BODY).flatten
  end
end
