import React, { Fragment } from "react";
import { Provider } from "react-redux";

import ErrorBoundary from "./ErrorBoundary";
import Board from "./Board";
import Header from "./Header";

import configureStore from "../store";

const store = configureStore();

const Application = () => (
    <ErrorBoundary>
        <Provider store={store}>
            <Fragment>
                <Header boards={flightPlanConfig.boards} />
                <Board />
            </Fragment>
        </Provider>
    </ErrorBoundary>
);

export default Application;
