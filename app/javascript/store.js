import { createStore, applyMiddleware, compose } from "redux";
import thunkMiddleware from "redux-thunk";

import rootReducer from "./reducers";

const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__
    ? window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__({ name: "FlightPlan app" })
    : compose;

let lastSwimlanes;

const persistSwimlaneCollapses = ({ entities }) => {
    try {
        const { swimlanes } = entities;

        if (lastSwimlanes !== swimlanes) {
            Object.values(swimlanes).forEach(({ id, isCollapsed }) => {
                const key = `swimlane:${id}:collapsed`;

                if (isCollapsed) {
                    localStorage.setItem(key, 1);
                } else {
                    localStorage.removeItem(key);
                }
            });
        }

        lastSwimlanes = swimlanes;
    } catch (error) {
        console.warn(error);
    }
};

const configureStore = () => {
    const store = createStore(
        rootReducer,
        composeEnhancers(applyMiddleware(thunkMiddleware))
    );

    if (module.hot) {
        module.hot.accept("./reducers", () => store.replaceReducer(rootReducer));
    }

    store.subscribe(() => persistSwimlaneCollapses(store.getState()));

    return store;
};

export default configureStore;
