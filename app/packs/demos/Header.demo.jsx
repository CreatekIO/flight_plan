import { useState, useEffect } from "react";

import { FakeStore, nextActions } from "./store";
import Header from "../components/Header";

const original = window.flightPlanConfig;

const boards = [
    { name: "Current Board", current: true },
    { name: "Another Board" }
].map((board, index) => {
    const id = board.id || index + 1;

    return { id, url: `/boards/${id}`, ...board };
});

const Scenario = ({ name, ...props }) => (
    <div className="py-3">
        <div
            data-scenario={name}
            className="header-scenario border border-dashed border-gray-200 border-b-0"
        >
            <Header.WrappedComponent {...props} />
        </div>
        <div className="text-center text-sm text-gray-600 mt-12 mb-6">
            {name}
        </div>
    </div>
);

Scenario.defaultProps = {
    boards,
    openPRsCount: 0,
    pullRequests: [],
    isWaiting: false
}

const Demo = () => {
    const [run, setRun] = useState(false);

    useEffect(() => {
        window.flightPlanConfig = {
            features: {},
            currentUser: { username: "rjpaskin" },
            api: {
                logoutURL: "/users/logout"
            }
        }

        setRun(true);

        const style = document.createElement("style");
        style.setAttribute("id", "header-styles");
        style.textContent = `
            .header-scenario > .fixed {
                position: relative;
            }

            [data-scenario="Open boards menu"] > .fixed > div:first-child [data-reach-menu] {
                display: block;
            }

            [data-scenario="Open user menu"] > .fixed {
                margin-bottom: 8rem;
            }

            [data-scenario="Open user menu"] > .fixed > div:nth-child(2) [data-reach-menu] {
                display: block;
            }

            [data-scenario="PR with multi-action"] > .fixed {
                margin-bottom: 10rem;
            }

            [data-scenario*="PR"] [data-reach-menu][style*="width"] {
                display: block;
            }
        `;

        document.querySelector("head").appendChild(style);

        return () => {
            window.flightPlanConfig = original;
            style.remove();
        }
    }, []);

    if (!run) return null;

    return (
        <FakeStore state={{
            current: {},
            entities: {
                pullRequests: {},
                repos: {}
            }
        }}>
            <div id="header-demo">
                <Scenario name="Loading" isWaiting={true} />
                <Scenario name="Open boards menu" />
                <Scenario name="Open user menu" />
                <Scenario name="One board" boards={boards.slice(0, 1)} />
                <Scenario name="No PRs" />
                <Scenario
                    name="PR with multi-action"
                    openPRsCount={1}
                    pullRequests={[{
                        id: 1,
                        name: "Test Repo",
                        pullRequests: [
                            {
                                id: 1,
                                number: "123",
                                html_url: "https://github.com",
                                title: "A pull request",
                                next_action: nextActions.multiGood
                            },
                            {
                                id: 2,
                                number: "456",
                                html_url: "https://github.com",
                                title: "Another pull request",
                                next_action: nextActions.singleGood
                            }
                        ]
                    }]}
                />
            </div>
        </FakeStore>
    );
};

export default Demo;
