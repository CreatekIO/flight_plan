import React, { Component, Fragment } from "react";
import { Dropdown, Popup } from "semantic-ui-react";

import NextActionButton from "./NextActionButton";
import AddNewIssueModal from './AddNewIssueModal';

const truncate = (text, length) => {
    if (text.length <= length) return text;

    return text.substring(0, length - 3) + "...";
};

const getOpenPRs = swimlanes => {
    let openPRs = {},
        count = 0;

    for (const swimlane of swimlanes) {
        for (const boardTicket of swimlane.board_tickets) {
            const repo_name = boardTicket.ticket.repo.name;

            for (const pullRequest of boardTicket.pull_requests) {
                if (pullRequest.remote_state === "open") {
                    openPRs[repo_name] = openPRs[repo_name] || [];
                    openPRs[repo_name].push(pullRequest);
                    count++;
                }
            }
        }
    }

    let openPRsByRepo = [];

    for (const repo_name in openPRs) {
        openPRsByRepo.push({ name: repo_name, pullRequests: openPRs[repo_name] });
    }

    return {
        count: count,
        pullRequests: openPRsByRepo.sort(
            (a, b) => b.pullRequests.length - a.pullRequests.length
        )
    };
};

export default class Header extends Component {
    state = { pullRequests: [], openPRsCount: 0, isWaiting: true };

    handleBoardLoad = (_, { swimlanes }) => {
        const { count: openPRsCount, pullRequests } = getOpenPRs(swimlanes);

        this.setState({ openPRsCount, pullRequests, isWaiting: false });
    };

    componentDidMount() {
        $(document).on("board:load", this.handleBoardLoad);
    }

    componentWillUnmount() {
        $(document).off("board:load", this.handleBoardLoad);
    }

    renderRepoPullRequests(repo) {
        return (
            <Fragment key={repo.name}>
                <h4 className="header">
                    {repo.name}
                    &nbsp;
                    <div className="ui circular label">{repo.pullRequests.length}</div>
                </h4>
                <div className="ui list">
                    {repo.pullRequests.map(pullRequest => (
                        <div className="item" key={pullRequest.id}>
                            <div className="right floated content">
                                <span className="action-btn">
                                    <NextActionButton
                                        {...pullRequest.next_action}
                                        className="compact mini"
                                    />
                                </span>
                            </div>
                            <div className="content">
                                <a href={pullRequest.html_url} target="_blank">
                                    #{pullRequest.remote_number}
                                    &nbsp;
                                    <span className="text-muted">
                                        {truncate(pullRequest.remote_title, 60)}
                                    </span>
                                </a>
                            </div>
                        </div>
                    ))}
                </div>
            </Fragment>
        );
    }

    renderPullRequestsItem() {
        const { isWaiting, openPRsCount, pullRequests } = this.state;

        if (isWaiting) {
            return <span className="item">Open Pull Requests</span>;
        } else {
            const item = (
                <span className="link item">
                    Open Pull Requests
                    <span className="ui circular label">{openPRsCount}</span>
                    <i className="dropdown icon" />
                </span>
            );

            return (
                <Popup trigger={item} on="click" flowing className="open-pull-requests">
                    {pullRequests.map(repo => this.renderRepoPullRequests(repo))}
                </Popup>
            );
        }
    }

    render() {
        const { boards } = this.props;
        const currentBoard = boards.find(board => board.current);

        return (
            <div className="ui menu board-header">
                <Dropdown text={currentBoard.name} className="item">
                    <Dropdown.Menu>
                        {boards.map(({ id, name, url, current }) => {
                            if (id === currentBoard.id) return null;

                            return (
                                <Dropdown.Item as="a" href={url} key={id}>
                                    {name}
                                </Dropdown.Item>
                            );
                        })}
                    </Dropdown.Menu>
                </Dropdown>

                <div className="right menu">
                    <AddNewIssueModal />

                    <a className="item" href={currentBoard.dashboardURL}>
                        PR Dashboard
                    </a>
                    {this.renderPullRequestsItem()}
                </div>
            </div>
        );
    }
}
