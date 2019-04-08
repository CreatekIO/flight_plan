import React, { Component, Fragment } from "react";
import { connect } from "react-redux";
import { denormalize } from "normalizr";
import { Modal } from "semantic-ui-react";
import showdown from "showdown";

import LabelList from "./LabelList";
import PullRequestList from "./PullRequestList";
import Avatar from "./Avatar";

import { boardTicket as boardTicketSchema } from "../schema";
import { loadFullTicket } from "../action_creators";

const markdownConverter = new showdown.Converter();
markdownConverter.setFlavor("github");
markdownConverter.setOption("openLinksInNewWindow", true);

const parseMarkdown = text => ({ __html: markdownConverter.makeHtml(text) });

const TicketEvent = ({ author, body, timestamp, action, divider }) => (
    <Fragment>
        {divider && <div className="ui divider" />}
        <div className="event">
            <div className="label">
                <Avatar username={author} />
            </div>
            <div className="content">
                <div className="summary">
                    <a
                        href={`https://github.com/${author}`}
                        target="_blank"
                        className="user"
                    >
                        {author}
                    </a>
                    &nbsp;{action}
                    <div className="date">{timestamp} ago</div>
                </div>
                <div
                    className="extra text gh-markdown"
                    dangerouslySetInnerHTML={parseMarkdown(body)}
                />
            </div>
        </div>
    </Fragment>
);

const Feed = ({ ticket, comments }) => {
    const { body, timestamp, creator } = ticket;

    return (
        <div className="ui feed">
            <TicketEvent
                author={creator}
                body={body}
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
                    divider
                />
            ))}
        </div>
    );
};

const Sidebar = ({
    state_durations,
    ticket,
    labels,
    milestone,
    pull_requests,
    assignees
}) => (
    <div className="ticket-sidebar">
        <div className="ui vertical text menu">
            <div className="item">
                <div className="header">Repo</div>
                <div>{ticket.repo.name}</div>
            </div>

            <div className="item">
                <div className="header">State</div>
                <div className={`ticket-state is-${ticket.state}`}>{ticket.state}</div>
            </div>

            <div className="item">
                <div className="header">Assignees</div>
                {assignees.length ? (
                    <div className="ui small list assignee-list">
                        {assignees.map(({ username }) => (
                            <div className="item">
                                <Avatar username={username} />
                                <div className="middle aligned content">
                                    <a
                                        href={`https://github.com/${username}`}
                                        target="_blank"
                                        className="header"
                                    >
                                        {username}
                                    </a>
                                </div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <em>No assignees</em>
                )}
            </div>

            <div className="item">
                <div className="header">Labels</div>
                <LabelList labels={labels} noLabels={<em>No labels</em>} />
            </div>

            <div className="item">
                <div className="header">Milestone</div>
                <LabelList milestone={milestone} noMilestone={<em>No milestone</em>} />
            </div>

            {!!state_durations.length && (
                <div className="item">
                    <div className="header">Durations</div>
                    <div className="durations">
                        {state_durations.map(({ id, name, duration }) => (
                            <div className="ui green fluid label" key={id}>
                                {name}
                                <div className="detail">{duration}</div>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            <div className="item">
                <div className="header">Pull requests</div>
                {pull_requests.length ? (
                    <PullRequestList pullRequests={pull_requests} listStyle="divided" />
                ) : (
                    <em>No pull requests</em>
                )}
            </div>
        </div>
    </div>
);

const ModalInner = ({
    state_durations,
    ticket,
    comments,
    labels,
    milestone,
    pull_requests,
    assignees
}) => {
    return (
        <React.Fragment>
            <div className="twelve wide column">
                <Feed ticket={ticket} comments={comments} />
            </div>
            <div className="four wide column">
                <Sidebar
                    state_durations={state_durations}
                    ticket={ticket}
                    labels={labels}
                    milestone={milestone}
                    pull_requests={pull_requests}
                    assignees={assignees}
                />
            </div>
        </React.Fragment>
    );
};

const Loading = () => (
    <React.Fragment>
        <div className="twelve wide column">
            <div className="ui basic segment">
                <div className="ui active inverted dimmer">
                    <div className="ui text loader">Loading</div>
                </div>
            </div>
        </div>
        <div className="four wide column" />
    </React.Fragment>
);

const choices = {
    undefined: Loading,
    loading: Loading,
    loaded: ModalInner
};

const TicketModal = ({
    trigger,
    loadFullTicket,
    id,
    url,
    state_durations,
    ticket,
    comments,
    pull_requests,
    labels,
    milestone,
    assignees,
    loading_state
}) => {
    const { remote_number, remote_title, html_url, repo } = ticket;
    const Inner = choices[`${loading_state}`];

    return (
        <Modal
            trigger={trigger}
            className="longer scrolling"
            closeIcon
            onOpen={() => loadFullTicket(id, url)}
        >
            <Modal.Header>
                <a href={html_url} target="_blank">
                    #{remote_number}
                </a>
                &nbsp;&nbsp;
                {remote_title}
            </Modal.Header>
            <Modal.Content scrolling>
                <div className="ui divided grid ticket-modal">
                    <Inner
                        state_durations={state_durations || []}
                        ticket={ticket}
                        comments={comments}
                        pull_requests={pull_requests}
                        labels={labels}
                        milestone={milestone}
                        assignees={assignees}
                    />
                </div>
            </Modal.Content>
        </Modal>
    );
};

const mapStateToProps = (_, { id }) => ({ entities }) => {
    const boardTicket = entities.boardTickets[id];

    return denormalize(boardTicket, boardTicketSchema, entities);
};

export default connect(
    mapStateToProps,
    { loadFullTicket }
)(TicketModal);
