Rails.application.reloader.to_prepare do
  Wisper.clear if Rails.env.development? || Rails.env.test?

  Label.subscribe(LabelBroadcast)
  Labelling.subscribe(LabellingBroadcast)
  Milestone.subscribe(MilestoneBroadcast)
  Ticket.subscribe(TicketBroadcast)
  TicketAssignment.subscribe(TicketAssignmentBroadcast)
end

if Rails.env.development? || Rails.env.test? || ENV['WISPER_LOGGING'].present?
  Wisper.configure do |config|
    config.broadcaster(
      :default,
      Wisper::Broadcasters::LoggerBroadcaster.new(
        Rails.logger,
        Wisper::Broadcasters::SendBroadcaster.new
      )
    )
  end
end
