import React, { Fragment, useEffect } from "react";
import { connect } from "react-redux";
import { navigate } from "@reach/router";

import Modal from "./Modal";
import Loading from "./Loading";
import Sidebar from "./TicketSidebar";
import Feed from "./TicketFeed";

import { loadFullTicketFromSlug, ticketModalClosed } from "../../action_creators";

const TicketModal = ({
    id,
    slug,
    number,
    ticket: { title, html_url },
    isLoaded,
    loadFullTicketFromSlug
}) => {
    const labelId = `ticket-modal-${id}`;

    useEffect(() => {
        loadFullTicketFromSlug(slug, number);
    }, [slug, number, loadFullTicketFromSlug]);

    return (
        <Modal
            isOpen
            onDismiss={() => navigate(flightPlanConfig.api.htmlBoardURL)}
            aria-labelledby={labelId}
        >
            <div
                className="text-lg border-b border-gray-300 p-4 pb-3 font-bold bg-white"
                id={labelId}
            >
                <a href={html_url} target="_blank" className="text-blue-500 hover:text-blue-600">
                    #{number}
                </a>
                &nbsp;&nbsp;
                {title}
            </div>

            <div className="p-4 grid grid-cols-4 gap-5 absolute top-14 inset-0 overflow-auto">
                <div className="col-span-3 relative">
                    <Feed id={id} />

                    {!isLoaded && (
                        <div className="flex justify-center text-gray-600 absolute inset-0 bg-white bg-opacity-50">
                            <Loading size="large" className="mt-14"/>
                        </div>
                    )}
                </div>

                <div className="col-span=1"> {/* this wrapper needed for position: sticky to work */}
                    {isLoaded && <Sidebar id={id} />}
                </div>
            </div>
        </Modal>
    );
}

const mapStateToProps = (_, { id: idFromProps, number, slug }) => ({
    entities: { boardTickets, tickets },
    current
}) => {
    const id = idFromProps || current.boardTicket;

    if (!id || !(id in boardTickets)) return {
        isLoaded: false,
        ticket: {
            html_url: `https://github.com/${slug}/${number}`
        }
    };

    const { loading_state, ...boardTicket } = boardTickets[id];
    const ticket = tickets[boardTicket.ticket];

    return {
        ...boardTicket,
        ticket,
        isLoaded: loading_state === "loaded"
    };
};

export default connect(mapStateToProps, { loadFullTicketFromSlug })(TicketModal);
