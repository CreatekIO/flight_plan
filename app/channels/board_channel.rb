class BoardChannel < ApplicationCable::Channel
  def subscribed
    board = Board.find(params[:id])

    stream_for(board)
  rescue ActiveRecord::RecordNotFound
    reject
  end
end
