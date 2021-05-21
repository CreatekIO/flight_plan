import { combineReducers, createReducer, isFulfilled, isAnyOf } from "@reduxjs/toolkit";

import boardTickets, { fetchTicket, moveTicket } from "./board_tickets";
import boards, { fetchBoard } from "./boards";
import labels from "./labels";
import pullRequests, { fetchNextActions } from "./pull_requests";
import swimlanes, { fetchSwimlaneTickets } from "./swimlanes";
import { ticketWasMoved } from "./websocket";
import { reduceReducers, upsert } from "./utils";

const isUpsertable = isAnyOf(
    isFulfilled(
        fetchBoard,
        fetchNextActions,
        fetchSwimlaneTickets,
        fetchTicket,
        moveTicket
    ),
    ticketWasMoved
);

// Initial state comes from `combined` reducer below
const reducer = createReducer(undefined, ({ addMatcher }) => {
    addMatcher(isUpsertable, (state, { payload: { entities }}) => {
        for (const type in entities) {
            upsert(state[type], entities[type]);
        }
    })
});

const nullReducer = (state = {}) => state;

const combined = combineReducers({
    boardTickets,
    boards,
    labels,
    pullRequests,
    swimlanes,
    // These need to be here otherwise `combineReducers`
    // discards the default state from the V1 reducer
    repos: nullReducer,
    tickets: nullReducer,
    milestones: nullReducer,
    comments: nullReducer
});

export default reduceReducers(reducer, combined);