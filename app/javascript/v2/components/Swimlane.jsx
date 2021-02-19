import React, { Fragment, useState, useCallback } from "react";
import { connect } from "react-redux";
import { Droppable } from "react-beautiful-dnd";
import classNames from "classnames";
import Octicon, { Fold, Unfold } from "@githubprimer/octicons-react";

import TicketCard from "./TicketCard";

import { loadSwimlaneTickets } from "../../action_creators";
import { collapseSwimlane, expandSwimlane } from "../slices/swimlanes";

// FIXME: implement
const Popup = ({ trigger }) => trigger;

// Performance optimisation as recommended by
// https://github.com/atlassian/react-beautiful-dnd#recommended-droppable-performance-optimisation
const TicketList = React.memo(({ boardTicketIds, shouldDisplayDuration }) => (
    <Fragment>
        {boardTicketIds.map((id, index) => (
            <TicketCard
                key={id}
                id={id}
                index={index}
                shouldDisplayDuration={shouldDisplayDuration}
            />
        ))}
    </Fragment>
));

const Swimlane = ({
    id,
    name,
    isCollapsed,
    board_tickets: boardTicketIds,
    display_duration: shouldDisplayDuration,
    next_board_tickets_url: nextBoardTicketsURL,
    all_board_tickets_loaded: areAllBoardTicketsLoaded,
    loadSwimlaneTickets,
    collapseSwimlane,
    expandSwimlane
}) => {
    const [isLoadingMore, setIsLoadingMore] = useState(false);

    const loadMore = useCallback(() => {
        setIsLoadingMore(true);
        loadSwimlaneTickets(id, nextBoardTicketsURL)
            .finally(() => setIsLoadingMore(false));
    }, [loadSwimlaneTickets, id, nextBoardTicketsURL]);

    return (
        <div
            className={classNames(
                "flex-none border-l-2 border-gray-200 bg-gray-50 text-gray-500",
                "transition-all duration-200 ease-out",
                { "w-64": !isCollapsed, "w-10": isCollapsed }
            )}
        >
            <div className={classNames(
                "border-gray-200 items-center relative",
                {
                    "border-b-2 h-10 flex justify-center": !isCollapsed,
                    "h-64": isCollapsed
                }
            )}>
                <span
                    className={classNames({
                        "inline-block absolute top-0 left-0 transform rotate-90 w-64 pl-16": isCollapsed
                    })}
                    style={{ transformOrigin: '20px center' }}
                >
                    {name}
                </span>

                <Popup
                    trigger={
                        <button
                            className={classNames(
                                "absolute pointer",
                                { "right-2": !isCollapsed, "right-3 top-2": isCollapsed }
                            )}
                            onClick={
                                () => isCollapsed
                                    ? expandSwimlane(id)
                                    : collapseSwimlane(id)
                            }
                        >
                            <Octicon
                                icon={isCollapsed ? Unfold : Fold}
                                className="transform rotate-90"
                            />
                        </button>
                    }
                    /* \u00A0 is a non-breaking space */
                    content={`${isCollapsed ? "Expand" : "Collapse"}\u00A0swimlane`}
                    size="mini"
                    hideOnScroll
                    inverted
                />
            </div>
            <Droppable droppableId={`Swimlane#swimlane-${id}`} isDropDisabled={isCollapsed}>
                {({ placeholder, innerRef, droppableProps }, { isDraggingOver }) => (
                    <div
                        ref={innerRef}
                        {...droppableProps}
                        className={classNames("px-3 pt-3 overflow-y-auto h-full", {
                            "bg-blue-50": isDraggingOver,
                            "hidden": isCollapsed
                        })}
                        style={{ ...droppableProps.style, height: 'calc(100vh - 98px)' }}
                    >
                        {isCollapsed || (
                            <Fragment>
                                <TicketList
                                    shouldDisplayDuration={shouldDisplayDuration}
                                    boardTicketIds={boardTicketIds}
                                />
                                {placeholder}
                                {areAllBoardTicketsLoaded || (
                                    <button
                                        className="w-full border border-gray-300 p-1 rounded text-gray-500 text-sm hover:bg-white mb-3"
                                        onClick={loadMore}
                                        disabled={isLoadingMore}
                                    >
                                        {isLoadingMore ? "Loading..." : "Load more"}
                                    </button>
                                )}
                            </Fragment>
                        )}
                    </div>
                )}
            </Droppable>
        </div>
    );
}

const mapStateToProps = (_, { id }) => ({ entities }) => entities.swimlanes[id];

export default connect(
    mapStateToProps,
    { loadSwimlaneTickets, collapseSwimlane, expandSwimlane }
)(Swimlane);
