import { configureStore, combineReducers } from "@reduxjs/toolkit";

import v1Reducer from "./v1_reducer";
import entities from "./slices/entities";
import { fetchBoard } from "./slices/boards";
import { reduceReducers } from "./slices/utils";
import wsNormalisationMiddleware from "./slices/websocket";
import api from "./api";

const current = (state = {}, action) => {
    if (fetchBoard.fulfilled.match(action)) {
        return { ...state, board: action.payload.boardId };
    } else {
        return state;
    }
};

const v2Reducer = combineReducers({ entities, current });

const rootReducer = reduceReducers(v1Reducer, v2Reducer);

const setupStore = () => configureStore({
    reducer: rootReducer,
    middleware: getDefaultMiddleware => getDefaultMiddleware({
        thunk: { extraArgument: api }
    }).concat(wsNormalisationMiddleware),
    devTools: {
        name: `FlightPlan/app@v2 [${process.env.NODE_ENV}]`
    }
});

export default setupStore;
