class RepoEvent::Status < RepoEvent
  alias_attribute :service, :context

  DEFAULT_ACTION = 'changed'.freeze

  def self.import(payload, _repo)
    super do |event|
      event.assign_attributes(
        action: DEFAULT_ACTION,
        state: payload[:state],
        branch: payload.dig(:branches, 0, :name),
        sha: payload[:sha],
        url: payload[:target_url],
        service: payload[:context]
      )
      yield(event) if block_given?
    end
  end
end
