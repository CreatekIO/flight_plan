import { combineReducers, createReducer } from "@reduxjs/toolkit";

import boardTickets from "./board_tickets";
import boards, { fetchBoard } from "./boards";
import labels from "./labels";
import swimlanes from "./swimlanes";
import { reduceReducers, upsert } from "./utils";

// Initial state comes from `combined` reducer below
const reducer = createReducer(undefined, ({ addCase }) => {
    addCase(fetchBoard.fulfilled, (state, { payload: { entities }}) => {
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
    swimlanes,
    // These need to be here otherwise `combineReducers`
    // discards the default state from the V1 reducer
    repos: nullReducer,
    tickets: nullReducer,
    pullRequests: nullReducer,
    milestones: nullReducer,
    comments: nullReducer
});

export default reduceReducers(reducer, combined);
