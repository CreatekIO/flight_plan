import React from "react";

import NextActionButton from "./NextActionButton";
import PullRequestIcon from "./PullRequestIcon";

const PullRequestLine = ({
    remote_state,
    merged,
    html_url,
    remote_title,
    remote_number,
    next_action
}) => (
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

export default function PullRequestList({ pullRequests, listStyle }) {
    return (
        <div className={`ui ${listStyle} list ticket-pull-requests`}>
            {pullRequests.map(pullRequest => (
                <PullRequestLine {...pullRequest} key={pullRequest.id} />
            ))}
        </div>
    );
}
