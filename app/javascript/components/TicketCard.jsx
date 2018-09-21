import React from "react";

import PullRequestList from "./PullRequestList";
import SwimlaneTransitionButton from "./SwimlaneTransitionButton";
import TicketModal from "./TicketModal";

export default function TicketCard(props) {
    const {
        ticket: { remote_number, remote_title, html_url, repo },
        display_duration,
        current_state_duration,
        url,
        pull_requests,
        transitions
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
                <TicketModal
                    trigger={<a className="issue-title">{remote_title}</a>}
                    number={remote_number}
                    title={remote_title}
                    ticketURL={html_url}
                    boardTicketURL={url}
                />
            </div>
            {display_duration && (
                <div className="content">
                    <div className="meta">Current state: {current_state_duration}</div>
                </div>
            )}
            {!!pull_requests.length && <PullRequestList pullRequests={pull_requests} />}
            {!!transitions.length && (
                <div className="extra content">
                    <SwimlaneTransitionButton transitions={transitions} />
                </div>
            )}
        </div>
    );
}
