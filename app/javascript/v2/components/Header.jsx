import React, { Component, Fragment, createRef } from "react";
import { connect } from "react-redux";
import classNames from "classnames";
import {
    Menu as ReachMenu,
    MenuButton,
    MenuLink,
    MenuPopover,
    MenuItems
} from "@reach/menu-button";

import NextActionButton from "./NextActionButton";
import Avatar from "./Avatar";
import AddNewIssueModal from "./AddNewIssueModal";
import { getOpenPRs } from "../../reducers/selectors";

// FIXME: implement
const Popup = ({ children }) => children;

const menuItemClasses = "block p-2 text-left";
const countClasses = "w-6 h-6 font-bold leading-6 ml-2 text-center rounded-full bg-gray-400 text-white text-xs";
const headerItemClasses = "block px-3 flex items-center justify-start hover:bg-gray-50 focus:outline-none focus:shadow-inner";

// See packs/application.css for additional styles
const Menu = ({
    title,
    pointing,
    children,
    className,
    position = "left",
    menuProps: { className: menuClass, ...menuProps } = {}
}) => (
    <div className={classNames("relative flex items-center justify-start", className)}>
        <ReachMenu>
            <MenuButton
                className={classNames("w-full h-full", headerItemClasses)}
            >
                {title}
                {pointing &&
                    <span className="text-xs ml-auto text-gray-600" aria-hidden>
                        &#9660;
                    </span>
                }
            </MenuButton>

            <MenuPopover
                portal={false}
                {...menuProps}
                className={classNames(
                    "absolute top-full focus:outline-none",
                    { "left-0": position === "left", "right-0": position === "right" }
                )}>
                <MenuItems
                    className={classNames(
                        "fp-header-menu p-0 bg-white shadow-xl rounded-b border-t border-gray-200 text-sm",
                        menuClass
                    )}
                >
                    {children}
                </MenuItems>
            </MenuPopover>
        </ReachMenu>
    </div>
);

const OpenPullRequests = ({ openPRsCount, pullRequests }) => {
    const title = <Fragment>
        Open Pull Requests
        <span className={classNames("mr-2", countClasses)}>
            {openPRsCount}
        </span>
    </Fragment>;

    return (
        <Menu
            title={title}
            menuProps={{ className: "p-3", style: { width: 600 }}}
            pointing
            position="right"
        >
            {pullRequests.map(({ id: repoId, name: repoName, pullRequests }) => (
                <Fragment key={repoId}>
                    <h4 className="text-lg font-bold text-left">
                        {repoName}
                        &nbsp;
                        <span className={classNames("inline-block align-text-top", countClasses)}>
                            {pullRequests.length}
                        </span>
                    </h4>
                    {pullRequests.map(({ id, next_action, html_url, number, title }) => (
                        <div className="mt-1 text-left relative" key={id}>
                            <MenuLink
                                href={html_url}
                                target="_blank"
                                className="text-gray-500 truncate p-1"
                            >
                                <span className="text-blue-500">#{number}</span>
                                {' '}
                                <span className="ml-1 text-gray-500">{title}</span>
                            </MenuLink>
                            {next_action && (
                                <NextActionButton
                                    {...next_action}
                                    className="absolute right-1 top-0"
                                    style={{ marginTop: 3 }}
                                />
                            )}
                        </div>
                    ))}
                </Fragment>
            ))}
        </Menu>
    );
};

const Header = ({ boards, isWaiting, openPRsCount, pullRequests }) => {
    const currentBoard = boards.find(board => board.current);

    return (
        <div className="fixed top-0 inset-x-0 h-14 z-10 border-b border-gray-200 divide-x flex flex-nowrap justify-end text-sm">
            <Menu
                pointing
                title={currentBoard.name}
                className="mr-auto border-r border-gray-200 w-56"
                menuProps={{ className: "w-56" }}
            >
                {boards.map(({ id, name, url }) => {
                    if (id === currentBoard.id) return null;

                    return (
                        <MenuLink href={`${url}?v2=1`} key={id} className={menuItemClasses}>
                            {name}
                        </MenuLink>
                    );
                })}
            </Menu>

            <AddNewIssueModal />
            <Menu
                menuProps={{ className: "w-48" }}
                title={<Avatar username={flightPlanConfig.currentUser.username} />}
            >
                <div className={menuItemClasses}>
                    Signed in as{" "}
                    <strong>@{flightPlanConfig.currentUser.username}</strong>
                </div>
                <hr/>
                <MenuLink
                    href={flightPlanConfig.api.logoutURL}
                    data-method="delete"
                    className={menuItemClasses}
                >
                    Sign out
                </MenuLink>
            </Menu>
            <a className={headerItemClasses} href={currentBoard.dashboardURL}>
                PR Dashboard
            </a>
            {isWaiting ? (
                <span className={headerItemClasses}>Open Pull Requests</span>
            ) : (
                <OpenPullRequests
                    openPRsCount={openPRsCount}
                    pullRequests={pullRequests}
                />
            )}
        </div>
    );
};

const mapStateToProps = ({ current, entities }) => {
    const { count: openPRsCount, pullRequests } = getOpenPRs(entities);

    return { openPRsCount, pullRequests, isWaiting: !current.board };
};

export default connect(mapStateToProps)(Header);
