Rails.application.reloader.to_prepare do
  Wisper.clear if Rails.env.development? || Rails.env.test?

  Wisper
    .subscribe(LabelBroadcast, scope: 'Label')
    .subscribe(LabellingBroadcast, scope: 'Labelling')
    .subscribe(MilestoneBroadcast, scope: 'Milestone')
    .subscribe(TicketBroadcast, scope: 'Ticket')
    .subscribe(TicketAssignmentBroadcast, scope: 'TicketAssignment')
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
