class TicketActions
  DEFAULTS = {
    'PullRequestStatuses' => {
      active: true,
      ignored_contexts: %w[codeclimate]
    },
    'Mergeability' => {
      active: true
    },
    'PullRequestReviews' => {
      active: true
    }
  }.freeze

  def self.each_for(pull_request, config: DEFAULTS)
    return enum_for(__method__, pull_request, config: config) unless block_given?

    config.each do |klass, conf|
      next unless conf[:active]

      check_class = const_get(klass)
      check = check_class.new(pull_request, conf)
      next unless check.applies?

      yield(check)
    end
  end

  def self.next_action_for(pull_request, user: nil, config: DEFAULTS)
    if user.present?
      next_action_for_user(pull_request, user: user, config: config)
    else
      next_action_for_team(pull_request, config: config)
    end
  end

  def self.next_action_for_team(pull_request, config: DEFAULTS)
    each_for(pull_request, config: config).each_with_object(SortedSet.new) do |check, collection|
      action = check.next_action

      next if action.blank?
      collection.add(action)
    end.first
  end

  def self.next_action_for_user(pull_request, user:, config: DEFAULTS)
    each_for(pull_request, config: config).each_with_object(SortedSet.new) do |check, collection|
      check.next_actions.each do |action|
        next unless action.applies_to?(user.uid)

        collection.add(action)
      end
    end.first
  end

  # In order of severity, worst to best
  ACTION_TYPES = %i[negative warning caution neutral positive].freeze


  ACTION_TYPES.each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      class #{type.to_s.classify}Action < Action; end
    RUBY
  end
end
