Rails.application.reloader.to_prepare do
  Wisper.clear if Rails.env.development? || Rails.env.test?

  Labelling.subscribe(LabellingBroadcast)
  Ticket.subscribe(TicketBroadcast)
end
