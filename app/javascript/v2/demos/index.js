import React from "react";
import { Router, Link } from "@reach/router";

import Header from "./Header.demo";
import TicketCard from "./TicketCard.demo";
import TicketSidebar from "./TicketSidebar.demo";

const Default = () => (
    <div className="h-screen flex items-center justify-center text-gray-400">
        Select a component from the menu
    </div>
);

const components = Object.entries({
    Header,
    TicketCard,
    TicketSidebar
});

const Root = () => (
    <div>
        <ul className="fixed inset-y-0 left-0 w-36 bg-gray-50 border-r border-gray-200">
            {components.map(([name]) => (
                <li key={name}>
                    <Link
                        to={`/__components__/${name}`}
                        className="block p-2 text-blue-500 hover:text-black"
                    >
                        {name}
                    </Link>
                </li>
            ))}
        </ul>

        <div className="ml-40 mr-3">
            <Router basepath="/__components__">
                {components.map(([name, Component]) => <Component key={name} path={name} />)}

                <Default default />
            </Router>
        </div>
    </div>
);

export default Root;
