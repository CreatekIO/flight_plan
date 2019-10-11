import ActionCable from "actioncable";
import { isFeatureDisabled } from "./features";

const ws = {
    get consumer() {
        this.actioncable = this.actioncable || ActionCable.createConsumer();
        return this.actioncable;
    }
};

const subscribe = (channel, onReceive) => {
    if (isFeatureDisabled("realtime_updates")) {
        return { unsubscribe: () => {} };
    }

    return ws.consumer.subscriptions.create(channel, { received: onReceive });
};

export const getBoardUpdates = (id, callback) =>
    subscribe({ channel: "BoardChannel", id }, callback);
