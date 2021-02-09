import { configureStore, combineReducers } from "@reduxjs/toolkit";

import v1Reducer from "../reducers";
import boardTickets from "./slices/board_tickets";
import labels from "./slices/labels";

const nullReducer = (state = {}) => state;

const entitiesReducer = combineReducers({
    boardTickets,
    labels,
    // These need to be here otherwise `combineReducers`
    // discards the default state from the V1 reducer
    boards: nullReducer,
    repos: nullReducer,
    swimlanes: nullReducer,
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

const persistSwimlaneCollapses = () => {
    let lastSwimlanes;

    return ({ entities: { swimlanes }}) => {
        try {
            if (lastSwimlanes !== swimlanes) {
                Object.values(swimlanes).forEach(({ id, isCollapsed }) => {
                    const key = `swimlane:${id}:collapsed`;

                    isCollapsed
                        ? localStorage.setItem(key, 1)
                        : localStorage.removeItem(key);
                });
            }

            lastSwimlanes = swimlanes;
        } catch (error) {
            console.warn(error);
        }
    };
};

const setupStore = () => {
    const store = configureStore({
        reducer: rootReducer,
        devTools: {
            name: `FlightPlan/app@v2 [${process.env.NODE_ENV}]`
        }
    });

    const persister = persistSwimlaneCollapses();
    store.subscribe(() => persister(store.getState()));

    return store;
}

export default setupStore;
