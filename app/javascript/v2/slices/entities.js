import { combineReducers, createReducer } from "@reduxjs/toolkit";

import boardTickets from "./board_tickets";
import labels from "./labels";
import swimlanes from "./swimlanes";
import { reduceReducers } from "./utils";

// Initial state comes from `combined` reducer below
const reducer = createReducer(undefined, () => {});

const nullReducer = (state = {}) => state;

const combined = combineReducers({
    boardTickets,
    labels,
    swimlanes,
    // These need to be here otherwise `combineReducers`
    // discards the default state from the V1 reducer
    boards: nullReducer,
    repos: nullReducer,
    tickets: nullReducer,
    pullRequests: nullReducer,
    milestones: nullReducer,
    comments: nullReducer
});

export default reduceReducers(reducer, combined);
