class MassTicketRefresher
  Batch = Struct.new(:number, :ids) do
    delegate :first, :last, :each, to: :ids

    def inspect
      "<Batch number=#{number} ids=#{first}..#{last}>"
    end

    def perform_in(delay)
      each { |id| TicketRefreshWorker.perform_in(delay, id) }
    end
  end

  def initialize(delay: 0.hours, per_hour: 100, dry_run: false)
    @delay = delay
    @per_hour = per_hour
    @dry_run = dry_run

    @scope = Ticket.default_scoped
    @scope = yield(@scope) if block_given?
  end

  def run
    log 'This is a dry run' if dry_run?
    log "Refreshing #{total} tickets from #{scope.to_sql}"

    batches.each do |batch|
      offset = offset_for(batch)
      log "Will run #{batch.inspect} @ #{offset.from_now}"

      next if dry_run?

      batch.perform_in(offset)
    end
  end

  private

  attr_reader :delay, :per_hour, :scope

  def dry_run?
    @dry_run
  end

  def batches
    @batches ||= scope.pluck(:id)
      .in_groups_of(per_hour, false)
      .each_with_index.map { |ids, number| Batch.new(number, ids) }
  end

  # Load scope into memory to calculate total, rather than issuing a
  # `COUNT` query, which may be out of date by the time we fetch the ids
  def total
    batches.sum { |batch| batch.ids.size }
  end

  def offset_for(batch)
    batch.number.hours + delay
  end

  def log(message)
    puts message unless defined?(Rails::Console)

    Rails.logger.tagged(self.class.name) do
      Rails.logger.info(message)
    end
  end
end
