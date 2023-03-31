import { Fragment } from "react";
import { connect } from "react-redux";
import { denormalize, schema } from "normalizr";
import { Draggable } from "react-beautiful-dnd";
import { Link } from "@gatsbyjs/reach-router";
import classNames from "classnames";

import PullRequest from "./PullRequest";
import Label, { Milestone } from "./Label";
import Avatar from "./Avatar";
import GitHubAppWarning from "./GitHubAppWarning";
import { isRepoDisabled } from "../slices/repos";

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
    shouldDisplayDuration,
    url,
    assignees,
    time_since_last_transition: timeSinceLastTransition,
    pull_requests: pullRequestIds,
    labels: labelIds,
    milestone: milestoneId,
    ticket: {
        number, title, html_url: htmlURL,
        repo,
        repo: { slug, name: repoName }
    }
}) => (
    <Draggable draggableId={`TicketCard/boardTicket#${id}`} index={index} isDragDisabled={isRepoDisabled(repo)}>
        {({ innerRef, draggableProps, dragHandleProps }, snapshot) => (
            <div
                ref={innerRef}
                {...draggableProps}
                className={classNames(
                    "flex flex-col rounded bg-white shadow border border-gray-400/50 mb-4 space-y-2 divide-y text-sm min-h-[88px]",
                    pullRequestIds.length ? "pb-1" : "pb-2"
                )}
                style={draggableProps.style}
            >
                <div {...dragHandleProps} className="px-2 pt-2">
                    <a className="pr-2 text-blue-600" href={htmlURL} target="_blank">
                        {number}
                    </a>
                    <span className="text-gray-400">{repoName}</span>
                    <span className="float-right">
                        <AssigneeStack assignees={assignees} />
                    </span>
                </div>

                <div className="px-2 flex grow flex-col justify-center border-transparent space-y-2">
                    <Link
                        to={`./${slug}/${number}`}
                        state={{ boardTicketId: id }}
                        className="text-blue-600 break-words block"
                    >
                        {title}
                    </Link>

                    {Boolean(milestoneId || labelIds.length) && (
                        <div>
                            {milestoneId && (
                                <Milestone id={milestoneId} className={classNames({ "mr-1": labelIds.length })} />
                            )}
                            {Boolean(labelIds.length) && labelIds.map((id, index) => (
                                <Label
                                    id={id}
                                    key={id}
                                    className={classNames({
                                        "mt-1": milestoneId || index > 0,
                                        "mr-1": index !== labelIds.length - 1
                                    })}
                                />
                            ))}
                        </div>
                    )}
                </div>
                {isRepoDisabled(repo) && <GitHubAppWarning verb="Dragging" className="px-2 pt-2"/>}
                {shouldDisplayDuration && (
                    <div className="px-2 pt-2 text-gray-400">
                        Since last move: {timeSinceLastTransition}
                    </div>
                )}
                {Boolean(pullRequestIds.length) && (
                    <div className="space-y-1 divide-y">
                        {pullRequestIds.map(id => (
                            <PullRequest key={id} id={id} className="px-2" />
                        ))}
                    </div>
                )}
            </div>
        )}
    </Draggable>
);

const boardTicketSchema = new schema.Entity("boardTickets", {
    ticket: new schema.Entity("tickets", {
        repo: new schema.Entity("repos")
    })
});

const mapStateToProps = (_, { id }) => ({ entities }) =>
    denormalize(id, boardTicketSchema, entities);


export default connect(mapStateToProps)(TicketCard);
