import React from "react";
import { Provider } from "react-redux";
import { Router, Match } from "@reach/router";

import ErrorBoundary from "./ErrorBoundary";
import Board from "./Board";
import Header from "./Header";
import TicketModal from "./TicketModal";

import configureStore from "../../store";

const store = configureStore();

const BoardWrapper = () => (
    <div className="flex flex-col h-screen">
        <Header boards={flightPlanConfig.boards} />
        <Board />
        <Match path=":owner/:repo/:number">
            {({ match, location: { state }}) => match && (
                <TicketModal
                    id={state && state.boardTicketId} /* may be null */
                    slug={`${match.owner}/${match.repo}`}
                    number={match.number}
                />
            )}
        </Match>
    </div>
);

const Application = () => (
    <ErrorBoundary>
        <Provider store={store}>
            <Router basepath={flightPlanConfig.api.htmlBoardURL}>
                <BoardWrapper path="/*extras"/>
            </Router>
        </Provider>
    </ErrorBoundary>
);

export default Application;
