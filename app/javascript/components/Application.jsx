import React, { Fragment } from "react";
import { Provider } from "react-redux";

import Board from "./Board";
import Header from "./Header";

import configureStore from "../store";

const store = configureStore();

const Application = () => (
    <Provider store={store}>
        <Fragment>
            <Header boards={flightPlanConfig.boards} />
            <Board />
        </Fragment>
    </Provider>
);

export default Application;
