import React from "react";
import { connect } from "react-redux";
import { denormalize } from "normalizr";
import { Draggable } from "react-beautiful-dnd";
import classNames from "classnames";

import PullRequestList from "./PullRequestList";
// import TicketModal from "./TicketModal";
import LabelList from "./LabelList";
import Avatar from "./Avatar";
import { boardTicket as boardTicketSchema } from "../../schema";

const TicketModal = ({ trigger }) => trigger;

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
        {({ innerRef, draggableProps, dragHandleProps }, snapshot) => (
            <div
                ref={innerRef}
                {...draggableProps}
                className={classNames(
                    "flex flex-col rounded bg-white shadow border border-gray-400 border-opacity-50 mb-4 space-y-2 divide-y text-sm",
                    pull_requests.length ? "pb-1" : "pb-2"
                )}
                style={{ ...draggableProps.style, minHeight: 88 }}
            >
                <div
                    {...dragHandleProps}
                    className="px-2 pt-2"
                >
                    <a className="pr-2 text-blue-600" href={html_url} target="_blank">
                        {number}
                    </a>
                    <span className="text-gray-400">{repo.name}</span>
                    <span className="right floated">
                        <AssigneeStack assignees={assignees} />
                    </span>
                </div>
                <div className="flex-grow px-2 flex flex-col justify-center border-transparent space-y-2">
                    <TicketModal
                        trigger={<a className="text-blue-600 break-words block">{title}</a>}
                        id={id}
                    />
                    {(labels.length || milestone) && (
                        <LabelList labels={labels} milestone={milestone} />
                    )}
                </div>
                {display_duration && (
                    <div className="px-2 pt-2 text-gray-400">
                        Since last move: {time_since_last_transition}
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
