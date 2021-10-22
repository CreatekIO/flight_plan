class LabelBroadcast < ApplicationBroadcast
  changed :name do
    broadcast_change(label, :name, to: label.repo.board)
  end

  changed :colour do
    broadcast_change(label, :colour, to: label.repo.board)
  end
end
