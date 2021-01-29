import React, { Fragment } from "react";
import { connect } from "react-redux";
import { Link } from "@reach/router";
import { denormalize, schema } from "normalizr";
import classNames from "classnames";
import Octicon, { Gear } from "@githubprimer/octicons-react";

import Label, { Milestone } from "./Label";
import PullRequest from "./PullRequest";
import Avatar from "./Avatar";

const GroupedPullRequestList = connect(
    (_, { id: boardTicketId }) => ({ entities: { pullRequests: allPRs, boardTickets, repos }}) => {
        const { pull_requests: pullRequestIds } = boardTickets[boardTicketId];
        if (!pullRequestIds) return { pullRequestsByRepo: [] };

        const grouped = pullRequestIds.reduce((out, id) => {
            const { repo: repoId } = allPRs[id];
            out[repoId] = out[repoId] || [];
            out[repoId].push(id);
            return out;
        }, {});

        const pullRequestsByRepo = Object.entries(grouped).map(
            ([repoId, pullRequestIds]) => ({ repo: repos[repoId], pullRequestIds })
        )

        return { pullRequestsByRepo };
    }
)(({ pullRequestsByRepo }) => {
    if (!pullRequestsByRepo.length) return <Blank message="No pull requests" />;

    return (
        <div className="text-sm">
            {pullRequestsByRepo.map(({ repo: { id, name }, pullRequestIds }) => (
                <Fragment key={id}>
                    {pullRequestsByRepo.length > 1 && (
                        <h3 className="uppercase text-gray-500 text-xs mt-1">{name}</h3>
                    )}
                    <div className="space-y-1">
                        {pullRequestIds.map(id => <PullRequest key={id} id={id} />)}
                    </div>
                </Fragment>
            ))}
        </div>
    );
});

const SidebarEntry = ({ title, children, url }) => (
    <Fragment>
        <h2 className="mt-3 text-gray-600">
            {Boolean(url) ? (
                <Link
                    to={url}
                    className="w-full flex items-center justify-start hover:text-blue-500 focus:text-blue-500 focus:outline-none"
                >
                    <span className="flex-grow text-left">{title}</span>
                    <Octicon icon={Gear} />
                </Link>
            ) : title}
        </h2>
        {children}
    </Fragment>
);

const Blank = ({ message }) => (
    <em className="text-sm text-gray-500">{message}</em>
);

const Assignee = ({ username }) => (
    <Fragment>
        <Avatar username={username} size="mini" className="inline mr-2" />
        <a
            href={`https://github.com/${username}`}
            target="_blank"
            className="text-blue-500 hover:text-blue-600"
        >
            {username}
        </a>
    </Fragment>
);

const ticketStateClasses = {
    open: 'text-github-green',
    closed: 'text-github-red'
}

const Sidebar = ({
    id,
    assignees,
    milestone: milestoneId,
    labels: labelIds,
    state_durations: stateDurations = [],
    ticket: { state, repo: { name: repoName }}
}) => (
    <div className="bg-white">
        <SidebarEntry title="Repo">
            <span className="text-sm text-gray-500">{repoName}</span>
        </SidebarEntry>

        <SidebarEntry title="State">
            <span className={classNames("uppercase text-lg", ticketStateClasses[state])}>
                {state}
            </span>
        </SidebarEntry>

        <SidebarEntry title="Assignees">
            {assignees.length ? (
                <div className="text-sm font-bold space-y-1 mt-1">
                    {assignees.map(({ username }) => <Assignee key={username} username={username} />)}
                </div>
            ) : (
                <Blank message="No assignees"/>
            )}
        </SidebarEntry>

        <SidebarEntry title="Labels" url="labels/edit">
            {labelIds.length ? (
                <div className="space-y-1">
                    {labelIds.map(id => <Label key={id} id={id} className="w-full" />)}
                </div>
            ) : <Blank message="No labels" />}
        </SidebarEntry>

        <SidebarEntry title="Milestone">
            {milestoneId ? <Milestone id={milestoneId} fullWidth /> : <Blank message="No milestone" />}
        </SidebarEntry>

        {Boolean(stateDurations.length) && (
            <SidebarEntry title="Durations">
                {stateDurations.map(({ id, name, duration }) => (
                    <div className="text-xs clear-right rounded border border-blue-200 bg-blue-50 px-2 py-1 mt-1" key={id}>
                        {name}
                        <div className="float-right">{duration}</div>
                    </div>
                ))}
            </SidebarEntry>
        )}

        <SidebarEntry title="Pull requests">
            <GroupedPullRequestList id={id} />
        </SidebarEntry>
    </div>
);

const boardTicketSchema = new schema.Entity("boardTickets", {
    ticket: new schema.Entity("tickets", {
        repo: new schema.Entity("repos")
    })
});

const mapStateToProps = (_, { id }) => ({ entities }) =>
    denormalize(id, boardTicketSchema, entities);

export default connect(mapStateToProps)(Sidebar);
