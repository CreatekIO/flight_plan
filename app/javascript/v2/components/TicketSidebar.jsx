import React, { Fragment } from "react";
import { connect } from "react-redux";
import { denormalize } from "normalizr";
import classNames from "classnames";

import LabelList from "./LabelList";
import PullRequestList from "./PullRequestList";
import Avatar from "./Avatar";

import {
    boardTicket as boardTicketSchema,
    pullRequestWithRepo as pullRequestWithRepoSchema
} from "../../schema";

const UnconnectedGroupedPullRequestList = ({ pullRequests }) => {
    const grouped = {};

    pullRequests.forEach(pullRequest => {
        grouped[pullRequest.repo.id] = grouped[pullRequest.repo.id] || [];
        grouped[pullRequest.repo.id].push(pullRequest);
    });

    if (Object.keys(grouped).length === 1) {
        return (
            <PullRequestList pullRequests={Object.values(grouped)[0]} listStyle={null} />
        );
    }

    return (
        <Fragment>
            {Object.values(grouped).map(prs => (
                <Fragment key={prs[0].repo.id}>
                    <div className="uppercase text-gray-500 text-xs mt-1">{prs[0].repo.name}</div>
                    <PullRequestList pullRequests={prs} listStyle={null} />
                </Fragment>
            ))}
        </Fragment>
    );
};

const prMapStateToProps = ({ entities }, { pullRequests }) => ({
    pullRequests: pullRequests.map(pullRequest =>
        denormalize(pullRequest, pullRequestWithRepoSchema, entities)
    )
});

const GroupedPullRequestList = connect(prMapStateToProps)(
    UnconnectedGroupedPullRequestList
);

const SidebarEntry = ({ title, children }) => (
    <Fragment>
        <h2 className="mt-3 text-gray-600">{title}</h2>
        {children}
    </Fragment>
);

const Blank = ({ message }) => (
    <em className="text-sm text-gray-500">{message}</em>
);

const ticketStateClasses = {
    open: 'text-github-green',
    closed: 'text-github-red'
}

const Sidebar = ({
    state_durations = [],
    ticket: { state, repo: { name: repoName }},
    labels,
    milestone,
    pull_requests,
    assignees
}) => (
    <div className="sticky top-3 pb-12 bg-white">
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
                    {assignees.map(({ username }) => (
                        <Fragment key={username}>
                            <Avatar username={username} size="mini" className="inline mr-2" />
                            <a
                                href={`https://github.com/${username}`}
                                target="_blank"
                                className="text-blue-500 hover:text-blue-600"
                            >
                                {username}
                            </a>
                        </Fragment>
                    ))}
                </div>
            ) : (
                <Blank message="No assignees"/>
            )}
        </SidebarEntry>

        <SidebarEntry title="Labels">
            <LabelList labels={labels} noLabels={<Blank message="No labels"/>} fullWidth />
        </SidebarEntry>

        <SidebarEntry title="Milestone">
            <LabelList
                milestone={milestone}
                noMilestone={<Blank message="No milestone"/>}
                fullWidth
            />
        </SidebarEntry>

        {!!state_durations.length && (
            <SidebarEntry title="Durations">
                {state_durations.map(({ id, name, duration }) => (
                    <div className="text-xs clear-right rounded border border-blue-200 bg-blue-50 px-2 py-1 mt-1" key={id}>
                        {name}
                        <div className="float-right">{duration}</div>
                    </div>
                ))}
            </SidebarEntry>
        )}

        <SidebarEntry title="Pull requests">
            {pull_requests.length ? (
                <GroupedPullRequestList pullRequests={pull_requests} />
            ) : (
                <Blank message="No pull requests"/>
            )}
        </SidebarEntry>
    </div>
);

const mapStateToProps = (_, { id }) => ({ entities }) =>
    denormalize(entities.boardTickets[id], boardTicketSchema, entities);

export default connect(mapStateToProps)(Sidebar);
