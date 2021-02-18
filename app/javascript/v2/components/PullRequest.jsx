import React from "react";
import { connect } from "react-redux";
import Octicon, { GitMerge, GitPullRequest } from "@githubprimer/octicons-react";
import classNames from "classnames";

import NextActionButton from "./NextActionButton";

// FIXME: implement
const Popup = ({ trigger }) => trigger;

const pullRequestIcons = {
    open: { icon: GitPullRequest, className: "text-github-green" },
    closed: { icon: GitPullRequest, className: "text-github-red" },
    merged: { icon: GitMerge, className: "text-github-purple" }
};

const PullRequest = ({
    className,
    state,
    merged,
    title,
    number,
    next_action: nextAction,
    html_url: htmlURL
}) => {
    const {
        className: iconClassName,
        icon
    } = pullRequestIcons[merged ? "merged" : state] || pullRequestIcons.open;

    return (
        <div className={classNames("flex pt-1", className)}>
            <div className="flex-grow">
                <Octicon icon={icon} className={classNames("mr-0.5", iconClassName)} />
                &nbsp;
                <Popup
                    trigger={
                        <a
                            href={htmlURL}
                            target="_blank"
                            className="text-blue-600 hover:text-blue-400 focus:text-blue-800"
                        >
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
            {/* At the moment, we don't have any 'next actions' for closed PRs */}
            {nextAction && state === "open" && (
                <NextActionButton {...nextAction} className="compact mini" />
            )}
        </div>
    );
}

const mapStateToProps = (_, { id }) => ({ entities: { pullRequests }}) => pullRequests[id];

export default connect(mapStateToProps)(PullRequest);
