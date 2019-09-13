import ActionCable from "actioncable";

const ws = {
    get consumer() {
        this.actioncable = this.actioncable || ActionCable.createConsumer();
        return this.actioncable;
    }
};

const subscribe = (channel, onReceive) => {
    const subscription = ws.consumer.subscriptions.create(channel, {
        received: onReceive
    });

    return subscription;
};

export const getBoardUpdates = (id, callback) =>
    subscribe({ channel: "BoardChannel", id }, callback);
