import { combineReducers } from "@reduxjs/toolkit";
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
        case "FULL_TICKET_LOADED":
            return { ...state, boardTicket: payload.id };
        case "TICKET_MODAL_CLOSED":
            return state.boardTicket === payload.boardTicketId
                ? { ...state, boardTicket: null }
                : state;
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
    pullRequests: {},
    labels: {},
    milestones: {},
    comments: {}
};

const entitiesReducer = (state = initialEntitiesState, { type, payload }) => {
    switch (type) {
        case "BOARD_TICKET_LOADED":
        case "FULL_TICKET_LOADED":
            return updateEntities(normalize(payload, boardTicketSchema).entities, state);
        default:
            return state;
    }
};

const rootReducer = combineReducers({
    entities: entitiesReducer,
    current
});

export default rootReducer;
