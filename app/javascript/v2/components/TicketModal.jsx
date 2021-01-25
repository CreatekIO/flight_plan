import React, { Component, Fragment } from "react";
import { connect } from "react-redux";
import { denormalize } from "normalizr";
import showdown from "showdown";
import classNames from "classnames";
import { navigate } from "@reach/router";

import Modal from "./Modal";
import LabelList from "./LabelList";
import PullRequestList from "./PullRequestList";
import Avatar from "./Avatar";
import Loading from "./Loading";

import {
    boardTicket as boardTicketSchema,
    pullRequestWithRepo as pullRequestWithRepoSchema
} from "../../schema";
import { loadFullTicketFromSlug, ticketModalClosed } from "../../action_creators";

const markdownConverter = new showdown.Converter();
markdownConverter.setFlavor("github");
markdownConverter.setOption("openLinksInNewWindow", true);

const parseMarkdown = text => ({ __html: markdownConverter.makeHtml(text) });

const TicketEvent = ({ author = "ghost", body, timestamp, action, divider }) => (
    <div className="flex mb-4">
        <Avatar username={author} />

        <div className="border border-gray-300 rounded ml-3 flex-grow">
            <div className="border-b border-gray-300 bg-gray-100 px-3 py-2 font-bold text-sm">
                <a
                    href={`https://github.com/${author}`}
                    target="_blank"
                    className="text-blue-500 hover:text-blue-600"
                >
                    {author}
                </a>
                &nbsp;{action}&nbsp;
                {timestamp && (
                    <span className="text-gray-400 text-xs font-normal">
                        {timestamp} ago
                    </span>
                )}
            </div>
            <div
                className="px-4 py-3 text-sm gh-markdown"
                dangerouslySetInnerHTML={parseMarkdown(body)}
            />
        </div>
    </div>
);

const Feed = ({ ticket, comments }) => {
    const { body, timestamp, creator } = ticket;

    return (
        <Fragment>
            <TicketEvent
                author={creator}
                body={body || "*No description*"}
                timestamp={timestamp}
                action="opened issue"
            />
            {comments.map(({ id, author, body, timestamp }) => (
                <TicketEvent
                    key={id}
                    author={author}
                    body={body}
                    timestamp={timestamp}
                    action="commented"
                />
            ))}
        </Fragment>
    );
};

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

const ticket_state_classes = {
    open: 'text-github-green',
    closed: 'text-github-red'
}

const Sidebar = ({
    state_durations,
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
            <span className={
                classNames("uppercase text-lg", ticket_state_classes[state])
            }>
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

class TicketModal extends Component {
    componentDidMount() {
        const { slug, number, loadFullTicketFromSlug } = this.props;
        loadFullTicketFromSlug(slug, number);
    }

    render() {
        const {
            loadFullTicketFromSlug,
            id,
            url,
            state_durations,
            ticket,
            comments = [],
            pull_requests,
            labels,
            milestone,
            assignees,
            loading_state
        } = this.props;
        const { number, title, html_url, repo } = ticket;
        const isLoaded = loading_state === "loaded";

        return (
            <Modal
                isOpen
                onDismiss={() => navigate(
                    `${flightPlanConfig.api.htmlBoardURL}?v2=1`
                )}
            >
                <div className="text-lg border-b border-gray-300 p-4 pb-3 font-bold bg-white">
                    <a href={html_url} target="_blank" className="text-blue-500 hover:text-blue-600">
                        #{number}
                    </a>
                    &nbsp;&nbsp;
                    {title}
                </div>

                <div className="p-4 grid grid-cols-4 gap-5 absolute top-14 inset-0 overflow-auto">
                    <div className="col-span-3 relative">
                        <Feed ticket={ticket} comments={comments} />

                        {!isLoaded && (
                            <div className="flex justify-center text-gray-600 absolute inset-0 bg-white bg-opacity-50">
                                <Loading size="large" className="mt-14"/>
                            </div>
                        )}
                    </div>

                    <div className="col-span=1"> {/* this wrapper needed for position: sticky to work */}
                        {isLoaded && (
                            <Sidebar
                                state_durations={state_durations || []}
                                ticket={ticket}
                                labels={labels}
                                milestone={milestone}
                                pull_requests={pull_requests}
                                assignees={assignees}
                            />
                        )}
                    </div>
                </div>
            </Modal>
        );
    }
}

const mapStateToProps = (_, { id: idFromProps, number, slug }) => ({ entities, current }) => {
    const id = idFromProps || current.boardTicket;

    if (!id || !(id in entities.boardTickets)) return {
        loading_state: "loading",
        ticket: {
            number,
            creator: "ghost",
            body: "<br/><br/><br/>",
            html_url: `https://github.com/${slug}/${number}`
        },
        repo: { slug }
    };

    const boardTicket = entities.boardTickets[id];

    return denormalize(boardTicket, boardTicketSchema, entities);
};

export default connect(
    mapStateToProps,
    { loadFullTicketFromSlug }
)(TicketModal);
