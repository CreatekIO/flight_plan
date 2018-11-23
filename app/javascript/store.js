import { createStore, applyMiddleware, compose } from "redux";
import thunkMiddleware from "redux-thunk";

import rootReducer from "./reducers";

const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

const configureStore = () => {
    const store = createStore(
        rootReducer,
        composeEnhancers(applyMiddleware(thunkMiddleware))
    );

    if (module.hot) {
        module.hot.accept("./reducers", () => store.replaceReducer(rootReducer));
    }

    return store;
};

export default configureStore;
