desc 'Enqueue workers to refresh tickets in DB'
task refresh_tickets: :environment do
  scope = Ticket.default_scoped

  state = ENV['STATE']
  scope = scope.where(remote_state: state) if state.present?

  order = ENV['ORDER'].presence_in(Ticket.column_names) || 'id'
  direction = ENV['DIR'].presence_in(%w[asc desc]) || 'desc'

  scope = scope.order(order => direction)

  count = scope.count
  per_hour = Integer(ENV.fetch('PER_HOUR', 100))
  offset = Integer(ENV.fetch('HOURS_FROM_NOW', 0))

  puts 'This is a dry run' if dry_run
  puts "Found #{count} tickets to refresh"

  scope.pluck(:id).in_groups_of(per_hour).each_with_index do |ids, batch_number|
    duration = (batch_number + offset).hours
    puts "ids #{ids.first}..#{ids.last} (#{ids.size} total), will run at #{duration.from_now}"

    next if dry_run

    ids.each { |id| TicketRefreshWorker.perform_in(duration, id) }
  end
end
