import React from "react";
import classNames from "classnames";
import { Popup } from "semantic-ui-react";

import NextActionButton from "./NextActionButton";
import PullRequestIcon from "./PullRequestIcon";

const PullRequestLine = ({
    state,
    merged,
    html_url,
    title,
    number,
    next_action
}) => (
    <div className="item">
        <div className="left floated content">
            <PullRequestIcon merged={merged} state={state} />
            &nbsp;
            <Popup
                trigger={
                    <a href={html_url} target="_blank">
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
            <div className="right floated content">
                <NextActionButton {...next_action} className="compact mini" />
            </div>
        )}
    </div>
);

export default function PullRequestList({ pullRequests, listStyle }) {
    return (
        <div
            className={classNames(
                "ui",
                { [listStyle]: listStyle },
                "list ticket-pull-requests"
            )}
        >
            {pullRequests.map(pullRequest => (
                <PullRequestLine {...pullRequest} key={pullRequest.id} />
            ))}
        </div>
    );
}
