import React from "react";

import PullRequestList from "./PullRequestList";

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
