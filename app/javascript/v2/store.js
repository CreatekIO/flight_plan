import { configureStore, combineReducers } from "@reduxjs/toolkit";

import entities from "./slices/entities";
import { fetchBoard } from "./slices/boards";
import wsNormalisationMiddleware from "./slices/websocket";
import api from "./api";

const current = (state = {}, action) => {
    if (fetchBoard.fulfilled.match(action)) {
        return { ...state, board: action.payload.boardId };
    } else {
        return state;
    }
};

const rootReducer = combineReducers({ entities, current });

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
