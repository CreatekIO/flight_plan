import React from "react";
import classNames from "classnames";

import NextActionButton from "./NextActionButton";
import PullRequestIcon from "./PullRequestIcon";

// FIXME: implement
const Popup = ({ trigger }) => trigger;

const PullRequestLine = ({
    state,
    merged,
    html_url,
    title,
    number,
    next_action
}) => (
    <div className="px-2 pt-1">
        <div className="left floated content">
            <PullRequestIcon merged={merged} state={state} />
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
