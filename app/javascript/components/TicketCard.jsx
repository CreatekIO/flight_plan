import React from "react";
import Octicon, { GitMerge, GitPullRequest } from "@githubprimer/octicons-react";

import NextActionButton from "./NextActionButton";

const PullRequestIcon = ({ merged, state }) => {
    if (merged) {
        return <Octicon icon={GitMerge} className="octicon is-merged" />;
    } else {
        return <Octicon icon={GitPullRequest} className={`octicon is-${state}`} />;
    }
};

const PullRequestLine = props => {
    const {
        remote_state,
        merged,
        html_url,
        remote_title,
        remote_number,
        next_action
    } = props;

    return (
        <div className="item">
            <div className="left floated content">
                <PullRequestIcon merged={merged} state={remote_state} />
                &nbsp;
                <a href={html_url} title={remote_title} target="_blank">
                    {remote_number}
                </a>
            </div>
            {next_action && (
                <div className="right floated content">
                    <NextActionButton {...next_action} className="compact mini" />
                </div>
            )}
        </div>
    );
};

const PullRequestList = ({ pullRequests }) => {
    return (
        <div className="ui celled list ticket-pull-requests">
            {pullRequests.map(pullRequest => (
                <PullRequestLine {...pullRequest} key={pullRequest.id} />
            ))}
        </div>
    );
};

export default function TicketCard(props) {
    const {
        ticket: { remote_number, remote_title, html_url, repo },
        display_duration,
        current_state_duration,
        pull_requests
    } = props;

    return (
        <div className="ui card">
            <div className="content">
                <a className="issue-number" href={html_url} target="_blank">
                    #{remote_number}
                </a>
                <span className="meta repo-name">{repo.name}</span>
            </div>
            <div className="content">
                <a className="issue-title">{remote_title}</a>
            </div>
            {display_duration && (
                <div className="content">
                    <div className="meta">Current state: {current_state_duration}</div>
                </div>
            )}
            <PullRequestList pullRequests={pull_requests} />
        </div>
    );
}
