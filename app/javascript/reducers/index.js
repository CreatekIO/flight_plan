import { combineReducers } from "redux";
import { normalize } from "normalizr";
import update from "immutability-helper";

import { board as boardSchema } from "../schema";

const updateEntities = (updates, entities) => {
    for (const type in updates) {
        const entitiesById = updates[type];

        for (const id in entitiesById) {
            entities = update(entities, {
                [type]: records =>
                    update(records || {}, { [id]: { $set: entitiesById[id] } })
            });
        }
    }

    return entities;
};

const current = (state = {}, { type, payload }) => {
    switch (type) {
        case "BOARD_LOAD":
            return { ...state, board: "" + payload.id };
        default:
            return state;
    }
};

const entities = (state = {}, { type, payload }) => {
    switch (type) {
        case "BOARD_LOAD":
            const { entities, result } = normalize(payload, boardSchema);

            return updateEntities(entities, state);
        default:
            return state;
    }
};

const sliceReducer = combineReducers({
    entities,
    current
});

const rootReducer = (state = {}, action) => {
    switch (action.type) {
        case "RESET":
            return {};
        default:
            return sliceReducer(state, action);
    }
};

export default rootReducer;
