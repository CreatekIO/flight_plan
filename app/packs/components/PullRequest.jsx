import { connect } from "react-redux";
import { GitMergeIcon, GitPullRequestIcon } from "@primer/octicons-react";
import classNames from "classnames";

import NextActionButton from "./NextActionButton";
import Tooltip from "./Tooltip";

const pullRequestIcons = {
    open: { Icon: GitPullRequestIcon, className: "text-github-green" },
    closed: { Icon: GitPullRequestIcon, className: "text-github-red" },
    merged: { Icon: GitMergeIcon, className: "text-github-purple" }
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
        Icon
    } = pullRequestIcons[merged ? "merged" : state] || pullRequestIcons.open;

    return (
        <div className={classNames("flex pt-1", className)}>
            <div className="grow">
                <Icon className={classNames("mr-0.5", iconClassName)} />
                &nbsp;
                <Tooltip label={title} placement="bottom-start">
                    <a
                        href={htmlURL}
                        target="_blank"
                        className="text-blue-600 hover:text-blue-400 focus:text-blue-800"
                    >
                        {number}
                    </a>
                </Tooltip>
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
