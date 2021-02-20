import { configureStore, combineReducers } from "@reduxjs/toolkit";

import v1Reducer from "./v1_reducer";
import entities from "./slices/entities";
import { reduceReducers } from "./slices/utils";
import api from "./api";

const nullReducer = (state = {}) => state;

const v2Reducer = combineReducers({
    entities,
    current: nullReducer
});

const rootReducer = reduceReducers(v1Reducer, v2Reducer);

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
