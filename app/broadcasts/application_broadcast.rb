class ApplicationBroadcast
  include ModelListener

  def self.inherited(klass)
    super

    model_key = klass.name.remove(/Broadcast$/).underscore
    klass.alias_method model_key, :record
  end

  private

  def blueprint(model, *args)
    "#{model.class}Blueprint".constantize.render_as_hash(model, *args)
  end

  def broadcast_to_board(event, payload, board: record.board)
    broadcast_to_model(board, event, payload)
  end

  def broadcast_change(record, attribute, to:)
    payload = {
      ReduxLoader.to_key(record) => {
        record.id => {
          id: record.id,
          ReduxLoader.to_key(attribute) => record.send(attribute)
        }
      }
    }

    event = "#{record.model_name.param_key}/#{attribute}_changed"
    broadcast_to_model(to, event, payload)
  end

  def broadcast_to_model(model, event, payload)
    payload = payload.transform_keys { |key| ReduxLoader.to_key(key) } if payload.is_a?(Hash)

    "#{model.class}Channel".constantize.broadcast_to(
      model,
      type: "ws/#{event}",
      meta: { userId: nil }, # FIXME
      payload: payload
    )
  end
end
