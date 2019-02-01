import React from "react";
import { connect } from "react-redux";
import { denormalize } from "normalizr";

import PullRequestList from "./PullRequestList";
import SwimlaneTransitionButton from "./SwimlaneTransitionButton";
import TicketModal from "./TicketModal";
import { boardTicket as boardTicketSchema } from "../schema";

const TicketCard = ({
    ticket: { remote_number, remote_title, html_url, repo },
    display_duration,
    time_since_last_transition,
    url,
    pull_requests,
    transitions
}) => (
    <div className="ui card">
        <div className="content">
            <a className="issue-number" href={html_url} target="_blank">
                #{remote_number}
            </a>
            <span className="meta repo-name">{repo.name}</span>
        </div>
        <div className="content">
            <TicketModal
                trigger={<a className="issue-title">{remote_title}</a>}
                number={remote_number}
                title={remote_title}
                ticketURL={html_url}
                boardTicketURL={url}
            />
        </div>
        {display_duration && (
            <div className="content">
                <div className="meta">Since last move: {time_since_last_transition}</div>
            </div>
        )}
        {!!pull_requests.length && <PullRequestList pullRequests={pull_requests} />}
        {!!transitions.length && (
            <div className="extra content">
                <SwimlaneTransitionButton transitions={transitions} />
            </div>
        )}
    </div>
);

const mapStateToProps = (_, { id }) => ({ entities }) => {
    const boardTicket = entities.boardTickets[id];

    return denormalize(boardTicket, boardTicketSchema, entities);
};

export default connect(mapStateToProps)(TicketCard);
