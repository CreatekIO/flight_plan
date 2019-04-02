import React from "react";
import { connect } from "react-redux";
import { denormalize } from "normalizr";
import { Draggable } from "react-beautiful-dnd";

import PullRequestList from "./PullRequestList";
import TicketModal from "./TicketModal";
import LabelList from "./LabelList";
import { boardTicket as boardTicketSchema } from "../schema";

const TicketCard = ({
    id,
    index,
    ticket: { remote_number, remote_title, html_url, repo },
    display_duration,
    time_since_last_transition,
    url,
    pull_requests,
    labels,
    milestone
}) => (
    <Draggable draggableId={`TicketCard#board-ticket-${id}`} index={index}>
        {(provided, snapshot) => (
            <div ref={provided.innerRef} {...provided.draggableProps} className="ui card">
                <div {...provided.dragHandleProps} className="content">
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
                    {(labels.length || milestone) && (
                        <LabelList labels={labels} milestone={milestone} />
                    )}
                </div>
                {display_duration && (
                    <div className="content">
                        <div className="meta">
                            Since last move: {time_since_last_transition}
                        </div>
                    </div>
                )}
                {!!pull_requests.length && (
                    <PullRequestList pullRequests={pull_requests} />
                )}
            </div>
        )}
    </Draggable>
);

const mapStateToProps = (_, { id }) => ({ entities }) => {
    const boardTicket = entities.boardTickets[id];

    return denormalize(boardTicket, boardTicketSchema, entities);
};

export default connect(mapStateToProps)(TicketCard);
