import { createStore } from "redux";
import rootReducer from "./reducers";

const { __REDUX_DEVTOOLS_EXTENSION__: devtools } = window;

const configureStore = () => {
    const store = createStore(rootReducer, devtools && devtools());

    if (module.hot) {
        module.hot.accept("./reducers", () => store.replaceReducer(rootReducer));
    }

    return store;
};

export default configureStore;
