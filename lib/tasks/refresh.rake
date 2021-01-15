desc 'Enqueue workers to refresh tickets in DB'
task refresh_tickets: :environment do
  params = {
    delay: Integer(ENV.fetch('HOURS_FROM_NOW', 0)).hours,
    per_hour: Integer(ENV.fetch('PER_HOUR', 100)),
    dry_run: ENV['DRY_RUN'].present?
  }

  MassTicketRefresher.new(**params) do |scope|
    state = ENV['STATE']
    scope = scope.where(state: state) if state.present?

    order = ENV['ORDER_BY'].presence_in(Ticket.column_names) || 'id'
    direction = ENV['DIR'].to_s.downcase.presence_in(%w[asc desc]) || 'desc'
    scope = scope.order(order => direction)

    scope
  end.run
end
