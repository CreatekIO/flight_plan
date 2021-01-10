import React, { Component, Fragment, createRef } from "react";
import { connect } from "react-redux";
import classNames from "classnames";

import NextActionButton from "./NextActionButton";
import Avatar from "./Avatar";
import AddNewIssueModal from "./AddNewIssueModal";
import { getOpenPRs } from "../../reducers/selectors";

// FIXME: implement
const Popup = ({ children }) => children;

class Menu extends Component {
    static defaultProps = { pointing: false, menuProps: {} };

    constructor(props) {
        super(props);
        this.state = { open: false };
        this.button = createRef();
    }

    handleClickOutside = ({ target }) => {
        const { current } = this.button;

        if (!this.state.open) return;
        if (current && current.contains(target)) return;

        this.setState({ open: false });
        current && current.blur();
    }

    toggleOpen = () => {
        this.setState(({ open }) => ({ open: !open }))
    }

    componentDidMount() {
        window.addEventListener("click", this.handleClickOutside);
    }

    componentWillUnmount() {
        window.removeEventListener("click", this.handleClickOutside);
    }

    render() {
        const {
            title,
            pointing,
            children,
            className,
            menuProps: { className: menuClass, ...menuProps }
        } = this.props;

        return (
            <button
                type="button"
                className={classNames("relative", headerItemClasses, className)}
                onClick={this.toggleOpen}
                ref={this.button}
            >
                {title}
                {pointing &&
                    <span className="text-xs ml-auto text-gray-600">&#9660;</span>
                }

                <div
                    {...menuProps}
                    className={classNames(
                        "absolute top-full right-0 min-w-full bg-white shadow-xl rounded-b border-t border-gray-200",
                        menuClass,
                        this.state.open || "hidden"
                    )}>
                    {children}
                </div>
            </button>
        );
    }
}

const menuItemClasses = "block p-2 text-left hover:bg-blue-50";
const countClasses = "w-6 h-6 font-bold leading-6 ml-2 text-center rounded-full bg-gray-400 text-white text-xs";

const RepoPullRequests = ({ name, pullRequests }) => (
    <Fragment>
        <h4 className="text-lg font-bold text-left">
            {name}
            &nbsp;
            <span className={classNames("inline-block align-text-top", countClasses)}>
                {pullRequests.length}
            </span>
        </h4>
        {pullRequests.map(({ id, next_action, html_url, number, title }) => (
            <div className="mt-2 mb-1 text-left flex" key={id}>
                <a
                    href={html_url}
                    target="_blank"
                    className="group text-gray-500 flex-grow truncate"
                >
                    <span className="text-blue-500 group-hover:text-blue-600">#{number}</span>
                    {' '}
                    <span className="ml-1 text-gray-500 group-hover:text-gray-600">{title}</span>
                </a>
                {next_action && (
                    <NextActionButton {...next_action} className="float-right" />
                )}
            </div>
        ))}
    </Fragment>
);

const headerItemClasses = "block px-3 flex items-center justify-start hover:bg-gray-50 focus:outline-none focus:shadow-inner";

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
        >
            {pullRequests.map(({ id, name, pullRequests }) => (
                <RepoPullRequests
                    key={id}
                    name={name}
                    pullRequests={pullRequests}
                />
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
            >
                {boards.map(({ id, name, url }) => {
                    if (id === currentBoard.id) return null;

                    return (
                        <a href={`${url}?v2=1`} key={id} className={menuItemClasses}>
                            {name}
                        </a>
                    );
                })}
            </Menu>

            <AddNewIssueModal />
            <a className={headerItemClasses} href="/features/v2_ui" data-method="delete">
                Back to V1
            </a>
            <Menu
                menuProps={{ className: "w-48" }}
                title={<Avatar username={flightPlanConfig.currentUser.username} />}
            >
                <div className={menuItemClasses}>
                    Signed in as{" "}
                    <strong>@{flightPlanConfig.currentUser.username}</strong>
                </div>
                <hr/>
                <a
                    href={flightPlanConfig.api.logoutURL}
                    data-method="delete"
                    className={menuItemClasses}
                >
                    Sign out
                </a>
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
