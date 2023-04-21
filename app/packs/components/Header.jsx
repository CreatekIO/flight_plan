import { Component, Fragment, createRef } from "react";
import { connect } from "react-redux";
import classNames from "classnames";
import { Menu } from "@headlessui/react";

import NextActionButton from "./NextActionButton";
import Avatar from "./Avatar";
import Loading from "./Loading";
import { getOpenPRs } from "../reducers/selectors";
import { isFeatureEnabled } from "../features";
import api from "../api";

const menuItemActiveClasses = "data-[headlessui-state=active]:bg-blue-50 data-[headlessui-state=active]:text-black";
const menuItemClasses = classNames("block p-2 text-left", menuItemActiveClasses);
const countClasses = "w-6 h-6 font-bold leading-6 ml-2 text-center rounded-full bg-gray-400 text-white text-xs";

const HeaderItem = ({
    as,
    disabled = false,
    children,
    className,
    ...props
}) => {
    const Component = as || (disabled ? "div" : "a");

    return (
        <Component
            className={classNames(
                "block px-3 flex items-center justify-start",
                { "hover:bg-gray-50 focus:outline-none focus:shadow-inner": !disabled },
                className
            )}
            {...props}
        >
            {children}
        </Component>
    );
}

const HeaderMenu = ({
    title,
    pointing,
    children,
    className,
    position = "left",
    menuProps: { className: menuClass, ...menuProps } = {}
}) => (
    <div className={classNames("relative flex items-center justify-start", className)}>
        <Menu>
            <HeaderItem
                as={Menu.Button}
                className="w-full h-full"
            >
                {title}
                {pointing &&
                    <span className="text-xs ml-auto text-gray-600" aria-hidden>
                        &#9660;
                    </span>
                }
            </HeaderItem>

            <div
                {...menuProps}
                className={classNames(
                    "absolute top-full focus:outline-none",
                    { "left-0": position === "left", "right-0": position === "right" }
                )}>
                <Menu.Items
                    unmount={false} /* This is mostly for the component demo, but does no harm otherwise */
                    className={classNames(
                        "p-0 bg-white shadow-xl rounded-b border-t border-gray-200 text-sm",
                        menuClass
                    )}
                >
                    {children}
                </Menu.Items>
            </div>
        </Menu>
    </div>
);

const OpenPullRequests = ({ openPRsCount, pullRequests: pullRequestsByRepo }) => {
    const title = <Fragment>
        Open Pull Requests
        <span className={classNames("mr-2", countClasses)}>
            {openPRsCount}
        </span>
    </Fragment>;

    if (openPRsCount === 0) return <HeaderItem disabled>{title}</HeaderItem>;

    return (
        <HeaderMenu
            title={title}
            menuProps={{ className: "p-3", style: { width: 600 }}}
            pointing
            position="right"
        >
            {pullRequestsByRepo.map(({ id: repoId, name: repoName, pullRequests }) => (
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
                            <Menu.Item
                                as="a"
                                href={html_url}
                                target="_blank"
                                className={classNames("text-gray-500 truncate p-1", menuItemActiveClasses)}
                            >
                                <span className="text-blue-500">#{number}</span>
                                {' '}
                                <span className="ml-1 text-gray-500">{title}</span>
                            </Menu.Item>
                            {next_action && (
                                <NextActionButton
                                    {...next_action}
                                    className="absolute right-1 top-0 mt-[3px]"
                                />
                            )}
                        </div>
                    ))}
                </Fragment>
            ))}
        </HeaderMenu>
    );
};

const BoardsMenu = ({ boards, currentBoard }) => {
    const btnClasses = "mr-auto border-r border-gray-200";
    const widthClass = "w-56";

    if (boards.length === 1) return (
        <HeaderItem disabled className={classNames(btnClasses, widthClass)}>
            {currentBoard.name}
        </HeaderItem>
    );

    const boardsToShow = boards.filter(({ id }) => id !== currentBoard.id);

    return (
        <HeaderMenu
            pointing
            title={currentBoard.name}
            className={classNames(btnClasses, widthClass)}
            menuProps={{ className: widthClass }}
        >
            {boardsToShow.map(({ id, name, url }) => {
                if (id === currentBoard.id) return null;

                return (
                    <Menu.Item as="a" href={url} key={id} className={menuItemClasses}>
                        {name}
                    </Menu.Item>
                );
            })}
        </HeaderMenu>
    );
};

const signOut = () => {
    api.deleteRequest(flightPlanConfig.api.logoutURL)
        .then(() => { window.location.href = "/" });
}

const Header = ({ boards, isWaiting, openPRsCount, pullRequests }) => {
    const currentBoard = boards.find(board => board.current);

    return (
        <div className="fixed top-0 inset-x-0 h-14 z-10 border-b border-gray-200 divide-x flex flex-nowrap justify-end text-sm">
            <BoardsMenu boards={boards} currentBoard={currentBoard} />
            <HeaderMenu
                menuProps={{ className: "w-48" }}
                title={<Avatar username={flightPlanConfig.currentUser.username} />}
            >
                <Menu.Item disabled as="div" className={menuItemClasses}>
                    Signed in as{" "}
                    <strong>@{flightPlanConfig.currentUser.username}</strong>
                </Menu.Item>
                <hr/>
                <Menu.Item as="button" className={classNames(menuItemClasses, "w-full")} onClick={signOut}>
                    Sign out
                </Menu.Item>
            </HeaderMenu>
            {isFeatureEnabled("kpis") && (
                <HeaderMenu title="Reports" menuProps={{ className: "w-max" }}>
                    <Menu.Item
                        as="a"
                        href={`/boards/${currentBoard.id}/kpis`}
                        className={classNames(menuItemClasses, "w-full")}
                    >
                        KPIs
                    </Menu.Item>
                    <Menu.Item
                        as="a" href={`/boards/${currentBoard.id}/cumulative_flow`}
                        className={classNames(menuItemClasses, "w-full")}
                    >
                        Cumulative flow
                    </Menu.Item>
                </HeaderMenu>
            )}
            {isWaiting ? (
                <HeaderItem disabled>
                    Open Pull Requests
                    <Loading className="ml-3 mr-2 text-gray-500" />
                </HeaderItem>
            ) : (
                <OpenPullRequests openPRsCount={openPRsCount} pullRequests={pullRequests} />
            )}
        </div>
    );
};

const mapStateToProps = ({ entities }, { boardId }) => {
    const { count: openPRsCount, pullRequests } = getOpenPRs(entities);

    return { openPRsCount, pullRequests, isWaiting: !(boardId in entities.boards) };
};

export default connect(mapStateToProps)(Header);
