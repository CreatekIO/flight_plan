import { combineReducers } from "redux";
import { normalize } from "normalizr";
import update from "immutability-helper";

import {
    board as boardSchema,
    repo as repoSchema,
    boardTicket as boardTicketSchema
} from "../schema";

const updateEntities = (updates, entities) => {
    for (const type in updates) {
        const entitiesById = updates[type];

        for (const id in entitiesById) {
            const record = entitiesById[id];

            entities = update(entities, {
                [type]: {
                    [id]: (current = {}) => update(current, { $merge: record })
                }
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

const initialEntitiesState = {
    boards: {},
    repos: {},
    swimlanes: {},
    boardTickets: {},
    tickets: {},
    pullRequests: {}
};

const entities = (state = initialEntitiesState, { type, payload }) => {
    switch (type) {
        case "BOARD_LOAD":
            const { entities, result } = normalize(payload, boardSchema);

            return updateEntities(entities, state);
        case "NEXT_ACTIONS_LOADED":
            return updateEntities(normalize(payload, [repoSchema]).entities, state);
        case "TICKET_MOVED":
            const { sourceId, sourceIndex, destinationId, destinationIndex } = payload;
            const movedCard = state.swimlanes[sourceId].board_tickets[sourceIndex];

            const transforms = [
                {
                    // Remove card from source swimlane...
                    [sourceId]: {
                        board_tickets: { $splice: [[sourceIndex, 1]] }
                    }
                },
                {
                    // ...and place it in destination swimlane
                    [destinationId]: {
                        board_tickets: { $splice: [[destinationIndex, 0, movedCard]] }
                    }
                }
            ];

            return transforms.reduce(
                (state, transform) => update(state, { swimlanes: transform }),
                state
            );
        case "SWIMLANE_TICKETS_LOADING":
            const { swimlaneId } = payload;

            return update(state, {
                swimlanes: { [swimlaneId]: { loading_board_tickets: { $set: true } } }
            });
        case "SWIMLANE_TICKETS_LOADED": {
            const { board_tickets, ...swimlane } = payload;

            const { entities, result: boardTicketIds } = normalize(board_tickets, [
                boardTicketSchema
            ]);

            const newEntities = updateEntities(entities, state);

            return update(newEntities, {
                swimlanes: {
                    [swimlane.id]: {
                        $merge: swimlane,
                        board_tickets: { $push: boardTicketIds },
                        loading_board_tickets: { $set: false }
                    }
                }
            });
        }
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
