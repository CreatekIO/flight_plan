import React from "react";
import { Provider } from "react-redux";
import { Router } from "@reach/router";

import ErrorBoundary from "./ErrorBoundary";
import Board from "./Board";
import Header from "./Header";
import TicketModal from "./TicketModal";

import configureStore from "../../store";

const store = configureStore();

const TicketModalWrapper = ({ owner, repo, number, location: { state }}) => (
    <TicketModal
        id={state && state.boardTicketId} /* may be null */
        slug={`${owner}/${repo}`}
        number={number}
    />
);

// Use a nested <Router> here instead of a <Match> so that
// further nested routers don't need to include the full
// owner-repo-number path in their routes
const BoardWrapper = () => (
    <div className="flex flex-col h-screen">
        <Header boards={flightPlanConfig.boards} />
        <Board />
        <Router>
            <TicketModalWrapper path=":owner/:repo/:number/*" />
        </Router>
    </div>
);

const Application = () => (
    <ErrorBoundary>
        <Provider store={store}>
            <Router basepath={flightPlanConfig.api.htmlBoardURL}>
                <BoardWrapper path="/*"/>
            </Router>
        </Provider>
    </ErrorBoundary>
);

export default Application;
