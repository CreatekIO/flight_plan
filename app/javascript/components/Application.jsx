import React, { Fragment } from "react";

import Board from "./Board";
import Header from "./Header";

const Application = props => (
    <Fragment>
        <Header boards={flightPlanConfig.boards} />
        <Board />
    </Fragment>
);

export default Application;
