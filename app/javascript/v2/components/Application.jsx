import React from "react";
import { Provider } from "react-redux";

import ErrorBoundary from "./ErrorBoundary";
import Board from "./Board";
import Header from "./Header";

import configureStore from "../../store";

const store = configureStore();

const Application = () => (
    <ErrorBoundary>
        <Provider store={store}>
            <div className="flex flex-col h-screen">
                <Header boards={flightPlanConfig.boards} />
                <Board />
            </div>
        </Provider>
    </ErrorBoundary>
);

export default Application;
