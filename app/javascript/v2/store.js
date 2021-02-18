import { configureStore, combineReducers } from "@reduxjs/toolkit";

import v1Reducer from "./v1_reducer";
import api from "./api";
import boardTickets from "./slices/board_tickets";
import labels from "./slices/labels";
import swimlanes from "./slices/swimlanes";

const nullReducer = (state = {}) => state;

const entitiesReducer = combineReducers({
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

const v2Reducer = combineReducers({
    entities: entitiesReducer,
    current: nullReducer
});

const REDUCERS = [v1Reducer, v2Reducer];

const rootReducer = (initialState, action) => REDUCERS.reduce(
    (prevState, reducer) => reducer(prevState, action),
    initialState
);

const setupStore = () => configureStore({
    reducer: rootReducer,
    middleware: getDefaultMiddleware => getDefaultMiddleware({
        thunk: { extraArgument: api }
    }),
    devTools: {
        name: `FlightPlan/app@v2 [${process.env.NODE_ENV}]`
    }
});

export default setupStore;
