import React from "react";
import { connect } from "react-redux";
import { denormalize } from "normalizr";
import { Draggable } from "react-beautiful-dnd";

import PullRequestList from "./PullRequestList";
import TicketModal from "./TicketModal";
import LabelList from "./LabelList";
import Avatar from "./Avatar";
import { boardTicket as boardTicketSchema } from "../schema";

const assigneeStackClass = {
    0: "none",
    1: "one",
    2: "two",
    3: "three"
};

const AssigneeStack = ({ assignees }) => (
    <span
        className={`assignee-stack has-${assigneeStackClass[assignees.length] || "many"}`}
    >
        {assignees.slice(0, 3).map(({ username }) => (
            <Avatar username={username} size="mini" key={username} />
        ))}
        {assignees.length > 3 && (
            /* We hide the third avatar in this case */
            <span className="meta">+{assignees.length - 2}</span>
        )}
    </span>
);

const TicketCard = ({
    id,
    index,
    ticket: { number, title, html_url, repo },
    display_duration,
    time_since_last_transition,
    url,
    pull_requests,
    labels,
    milestone,
    assignees
}) => (
    <Draggable draggableId={`TicketCard#board-ticket-${id}`} index={index}>
        {(provided, snapshot) => (
            <div
                ref={provided.innerRef}
                {...provided.draggableProps}
                className="ui card ticket-card"
            >
                <div
                    {...provided.dragHandleProps}
                    className="content ticket-card--header"
                >
                    <a className="issue-number" href={html_url} target="_blank">
                        {number}
                    </a>
                    <span className="meta repo-name">{repo.name}</span>
                    <span className="right floated">
                        <AssigneeStack assignees={assignees} />
                    </span>
                </div>
                <div className="content ticket-card--title">
                    <TicketModal
                        trigger={<a className="issue-title">{title}</a>}
                        id={id}
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
                    <PullRequestList pullRequests={pull_requests} listStyle="celled" />
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
