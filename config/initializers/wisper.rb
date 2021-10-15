Rails.application.reloader.to_prepare do
  Wisper.clear if Rails.env.development? || Rails.env.test?

  Label.subscribe(LabelBroadcast)
  Labelling.subscribe(LabellingBroadcast)
  Milestone.subscribe(MilestoneBroadcast)
  Ticket.subscribe(TicketBroadcast)
  TicketAssignment.subscribe(TicketAssignmentBroadcast)
end
