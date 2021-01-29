import React from "react";
import Octicon, { GitMerge, GitPullRequest } from "@githubprimer/octicons-react";
import classNames from "classnames";

import NextActionButton from "./NextActionButton";

// FIXME: implement
const Popup = ({ trigger }) => trigger;

const pull_request_icons = {
    open: { icon: GitPullRequest, className: "text-github-green" },
    closed: { icon: GitPullRequest, className: "text-github-red" },
    merged: { icon: GitMerge, className: "text-github-purple" }
};

const PullRequestLine = ({
    state,
    merged,
    html_url,
    title,
    number,
    next_action
}) => {
    const {
        className: iconClassName,
        icon
    } = pull_request_icons[merged ? "merged" : state] || pull_request_icons.open;

    return (
        <div className="px-2 pt-1 clear-both">
            <div className="float-left">
                <Octicon icon={icon} className={classNames("mr-0.5", iconClassName)} />
                &nbsp;
                <Popup
                    trigger={
                        <a href={html_url} target="_blank" className="text-blue-600 hover:text-blue-400 focus:text-blue-800">
                            {number}
                        </a>
                    }
                    content={title}
                    position="right center"
                    size="mini"
                    hideOnScroll
                    inverted
                />
            </div>
            {next_action && (
                <div className="float-right">
                    <NextActionButton {...next_action} className="compact mini" />
                </div>
            )}
        </div>
    );
}

export default function PullRequestList({ pullRequests, listStyle }) {
    return (
        <div
            className={classNames(
                "space-y-1",
                { "divide-y": listStyle === "celled" }
            )}
        >
            {pullRequests.map(pullRequest => (
                <PullRequestLine {...pullRequest} key={pullRequest.id} />
            ))}
        </div>
    );
}
