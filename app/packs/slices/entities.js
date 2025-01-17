import { combineReducers, createReducer, isFulfilled, isAnyOf } from "@reduxjs/toolkit";

import boardTickets, { fetchTicket, moveTicket } from "./board_tickets";
import boards, { fetchBoard } from "./boards";
import labels from "./labels";
import pullRequests, { fetchNextActions } from "./pull_requests";
import repos from "./repos";
import swimlanes, { fetchSwimlaneTickets } from "./swimlanes";
import {
    ticketWasMoved,
    ticketRetitled,
    ticketMilestoned,
    ticketDemilestoned,
    milestoneRetitled,
    labelRenamed,
    labelRecoloured
} from "./websocket";
import { reduceReducers, upsert } from "./utils";

const isUpsertable = isAnyOf(
    isFulfilled(
        fetchBoard,
        fetchNextActions,
        fetchSwimlaneTickets,
        fetchTicket,
        moveTicket
    ),
    ticketWasMoved,
    ticketRetitled,
    ticketMilestoned,
    ticketDemilestoned,
    milestoneRetitled,
    labelRenamed,
    labelRecoloured
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
    repos,
    swimlanes,
    // These need to be here otherwise `combineReducers`
    // discards these keys
    tickets: nullReducer,
    milestones: nullReducer,
    comments: nullReducer
});

export default reduceReducers(reducer, combined);
