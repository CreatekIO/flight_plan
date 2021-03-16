import React, { Component, Fragment } from "react";
import { Dropdown, Popup } from "semantic-ui-react";
import { connect } from "react-redux";

import NextActionButton from "./NextActionButton";
import Avatar from "./Avatar";
import AddNewIssueModal from "./AddNewIssueModal";
import { getOpenPRs } from "../reducers/selectors";
import { isFeatureEnabled } from "../features";

const truncate = (text, length) => {
    if (text.length <= length) return text;

    return text.substring(0, length - 3) + "...";
};

const RepoPullRequests = ({ repo }) => (
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
                            {pullRequest.next_action && (
                                <NextActionButton
                                    {...pullRequest.next_action}
                                    className="compact mini"
                                />
                            )}
                        </span>
                    </div>
                    <div className="content">
                        <a href={pullRequest.html_url} target="_blank">
                            #{pullRequest.number}
                            &nbsp;
                            <span className="text-muted">
                                {truncate(pullRequest.title, 60)}
                            </span>
                        </a>
                    </div>
                </div>
            ))}
        </div>
    </Fragment>
);

const WaitingItem = () => <span className="item">Open Pull Requests</span>;

const OpenPullRequests = ({ openPRsCount, pullRequests }) => {
    const item = (
        <span className="link item">
            Open Pull Requests
            <span className="ui circular label">{openPRsCount}</span>
            <i className="dropdown icon" />
        </span>
    );

    return (
        <Popup
            trigger={item}
            on="click"
            flowing
            hideOnScroll
            className="open-pull-requests"
        >
            {pullRequests.map(repo => (
                <RepoPullRequests repo={repo} key={repo.id} />
            ))}
        </Popup>
    );
};

const Header = ({ boards, isWaiting, openPRsCount, pullRequests }) => {
    const currentBoard = boards.find(board => board.current);

    return (
        <div className="ui top fixed menu board-header">
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
                {isFeatureEnabled("self_serve_features") && (
                    <a href="/user/features/v2_ui" data-method="post" className="link item">
                        Try out V2
                        <span className="ui circular orange label">Beta</span>
                    </a>
                )}
                <Dropdown
                    trigger={<Avatar username={flightPlanConfig.currentUser.username} />}
                    className="item user-menu"
                    pointing="top left"
                    icon={null}
                >
                    <Dropdown.Menu>
                        <Dropdown.Header>
                            Signed in as{" "}
                            <strong>@{flightPlanConfig.currentUser.username}</strong>
                        </Dropdown.Header>
                        <Dropdown.Divider />
                        <Dropdown.Item
                            as="a"
                            href={flightPlanConfig.api.logoutURL}
                            data-method="delete"
                        >
                            Sign out
                        </Dropdown.Item>
                    </Dropdown.Menu>
                </Dropdown>
                {isFeatureEnabled("kpis") && (
                    <a className="item" href={currentBoard.kpisURL}>KPIs</a>
                )}
                {isWaiting ? (
                    <span className="item">Open Pull Requests</span>
                ) : (
                    <OpenPullRequests
                        openPRsCount={openPRsCount}
                        pullRequests={pullRequests}
                    />
                )}
            </div>
        </div>
    );
};

const mapStateToProps = ({ current, entities }) => {
    const { count: openPRsCount, pullRequests } = getOpenPRs(entities);

    return { openPRsCount, pullRequests, isWaiting: !current.board };
};

export default connect(mapStateToProps)(Header);
