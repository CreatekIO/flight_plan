class MilestoneBroadcast < ApplicationBroadcast
  changed :title do
    broadcast_change(milestone, :title, to: milestone.repo.board)
  end
end
