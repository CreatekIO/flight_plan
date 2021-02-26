import React, { useEffect } from "react";
import { Provider } from "react-redux";
import { Router } from "@reach/router";

import ErrorBoundary from "./ErrorBoundary";
import Board from "./Board";
import Header from "./Header";
import TicketModal from "./TicketModal";
import Notifications from "./Notifications";

import configureStore from "../store";
import { rehydrateStore } from "../slices/utils";

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
const BoardWrapper = ({ children, ...props }) => (
    <div className="flex flex-col h-screen">
        <Header boards={flightPlanConfig.boards} boardId={props.boardId} />
        <Board {...props} />
        <Router>
            <TicketModal path=":owner/:repo/:number/*" />
        </Router>
    </div>
);

const Application = () => {
    useEffect(() => { store.dispatch(rehydrateStore()) }, []);

    return (
        <ErrorBoundary>
            <Provider store={store}>
                <Router>
                    <BoardWrapper path="boards/:boardId/*" />
                </Router>
            </Provider>

            <Notifications />
        </ErrorBoundary>
    );
}

export default Application;
