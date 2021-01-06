import React, { Fragment } from "react";
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

const assigneeClassNames = {
    1: [/* no classes */],
    2: ["mr-0.5", /* no classes */],
    3: [
        "-mr-3 z-20 ring-2 ring-white",
        "-mr-3 z-10 ring-2 ring-white",
        /* no classes */
    ],
    // only two avatars shown in this case
    4: ["-ml-6 z-20 ring-2 ring-white", "-ml-3 mr-1 z-10"]
};

const AssigneeStack = ({ assignees }) => {
    const numOfAvatars = assignees.length <= 3 ? 3 : 2;
    const classes = assigneeClassNames[assignees.length] || assigneeClassNames[4];

    return (
        <Fragment>
            {assignees.slice(0, numOfAvatars).map(({ username }, index) => (
                <Avatar
                    key={username}
                    username={username}
                    size="mini"
                    className={
                        classNames(
                            "inline align-middle relative",
                            classes[index]
                        )
                    }
                />
            ))}
            {assignees.length > 3 && (
                <span className="text-sm align-middle">
                    +{assignees.length - numOfAvatars}
                </span>
            )}
        </Fragment>
    );
}

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
                    <span className="float-right">
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
