import React, { Fragment, useState, useEffect } from "react";
import { connect } from "react-redux";
import { navigate, Link, useLocation } from "@reach/router";
import classNames from "classnames";

import { useConstrainedMatch } from "../hooks";
import Modal from "./Modal";
import Loading from "./Loading";
import Sidebar from "./TicketSidebar";
import Feed from "./TicketFeed";
import FormWrapper from "./TicketFormWrapper";
import LabelPicker from "./LabelPicker";
import { fetchTicket } from "../slices/board_tickets";

// sidebar width = w-56 = 14rem
// sidebar gutter = pl-5 = 1.25rem
// => sum = 15.25rem
const feedWidth = "calc(100% - 15.25rem)";

const transitionClasses = "transform transition-transform duration-150";
const TRANSITION_DURATION = 150; // should match `duration-*` class above

const EDITORS = {
    labels: LabelPicker,
    assignees: () => (<FormWrapper label="Edit assignees" backPath="." />),
    milestone: () => (<FormWrapper label="Edit milestone" backPath="." />)
};

const TicketModal = ({
    id,
    slug,
    number,
    ticket: { title, html_url: htmlURL },
    fetchTicket,
    ticketModalClosed
}) => {
    const labelId = `ticket-modal-${id}`;

    const { section } = useConstrainedMatch(
        ":section/edit",
        { section: ["labels", "assignees", "milestone"] }
    ) || {};
    const [sectionWas, setSectionWas] = useState(null);

    useEffect(() => { section && setSectionWas(section) }, [section]);

    const activeSection = section || sectionWas;
    const ActiveEditor = activeSection && EDITORS[activeSection];

    const [isLoaded, setIsLoaded] = useState(false);

    const { href } = useLocation();

    useEffect(() => {
        fetchTicket({ slug, number })
            .then(({ meta, payload: { boardTicketId }}) => {
                if (meta.requestStatus === "fulfilled") {
                    return navigate(href, { state: { boardTicketId }, replace: true })
                }
            })
            .finally(() => setIsLoaded(true))
    }, [slug, number, fetchTicket]);

    return (
        <Modal
            isOpen
            onDismiss={() => {
                navigate(flightPlanConfig.api.htmlBoardURL);
            }}
            aria-labelledby={labelId}
        >
            <div
                className="text-lg border-b border-gray-300 p-4 pb-3 font-bold bg-white"
                id={labelId}
            >
                <a href={htmlURL} target="_blank" className="text-blue-500 hover:text-blue-600">
                    #{number}
                </a>
                &nbsp;&nbsp;
                {title}
            </div>

            <div className="absolute top-14 inset-0 overflow-auto mt-px">
                {isLoaded && (
                    <div className="sticky w-56 top-4 right-0 ml-auto overflow-x-hidden">
                        <Sidebar
                            id={id}
                            className={classNames(
                                "pr-3 pb-12",
                                transitionClasses,
                                section ? "-translate-x-56" : "translate-x-0"
                            )}
                        />
                    </div>
                )}

                {/* Put <Feed/> after <Sidebar/> in the DOM so that it has a higher z-index */}
                <div className="absolute left-4 top-4 pr-5 bg-white" style={{ width: feedWidth }}>
                    <Feed id={id} />

                    {!isLoaded && (
                        <div className="flex justify-center text-gray-600 absolute inset-0 bg-white bg-opacity-50">
                            <Loading size="large" className="mt-14"/>
                        </div>
                    )}
                </div>
            </div>

            {isLoaded && (
                <div
                    className={classNames(
                        "w-56 absolute top-14 bottom-0 right-0 pt-4 bg-white mt-px border-l border-gray-300 bg-gray-100",
                        transitionClasses,
                        section ? "translate-x-0" : "translate-x-56"
                    )}
                    /* Ensure we keep the editor in the DOM until the transition ends */
                    onTransitionEnd={() => section || setSectionWas(null)}
                >
                    {/* As soon as we navigate to a section, mount the corresponding editor */}
                    {/* so that it's present before the transition starts */}
                    {Boolean(ActiveEditor) && (
                        <ActiveEditor boardTicketId={id} backPath="." enableAfter={TRANSITION_DURATION} />
                    )}
                </div>
            )}
        </Modal>
    );
}

const mapStateToProps = (_, { number, slug }) => {
    const loading = {
        ticket: {
            html_url: `https://github.com/${slug}/${number}`
        }
    };

    return ({ entities: { boardTickets, tickets }}, { id }) => {
        const boardTicket = id && boardTickets[id];
        if (!boardTicket) return loading;

        const ticket = tickets[boardTicket.ticket];
        return { ...boardTicket, ticket };
    };
};

export default connect(mapStateToProps, { fetchTicket })(TicketModal);
