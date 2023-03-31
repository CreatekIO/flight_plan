import { memo, Fragment, useState, useCallback } from "react";
import { useDispatch, useSelector } from "react-redux";
import { Droppable } from "react-beautiful-dnd";
import classNames from "classnames";
import { FoldIcon, UnfoldIcon } from "@primer/octicons-react";

import { useEntity } from "../hooks";
import TicketCard from "./TicketCard";
import Tooltip from "./Tooltip";

import {
    collapseSwimlane,
    expandSwimlane,
    fetchSwimlaneTickets
} from "../slices/swimlanes";

// Performance optimisation as recommended by
// https://github.com/atlassian/react-beautiful-dnd#recommended-droppable-performance-optimisation
const TicketList = memo(({ boardTicketIds, shouldDisplayDuration }) => (
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

const HEADER_HEIGHT = 98; // px

const Swimlane = ({ id }) => {
    const [isLoadingMore, setIsLoadingMore] = useState(false);
    const dispatch = useDispatch();

    const {
        name,
        isCollapsed,
        board_tickets: boardTicketIds,
        display_duration: shouldDisplayDuration,
        next_board_tickets_url: nextBoardTicketsURL,
        all_board_tickets_loaded: areAllBoardTicketsLoaded
    } = useEntity("swimlane", id);

    const loadMore = useCallback(() => {
        setIsLoadingMore(true);
        dispatch(fetchSwimlaneTickets(nextBoardTicketsURL))
            .finally(() => setIsLoadingMore(false));
    }, [fetchSwimlaneTickets, nextBoardTicketsURL]);

    const scrollbarHeight = useSelector(({ ui: { scrollbarHeight }}) => scrollbarHeight);
    const heightOffset = HEADER_HEIGHT + scrollbarHeight;

    const Icon = isCollapsed ? UnfoldIcon : FoldIcon;

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
                    className={classNames(
                        "origin-[20px_center]",
                        { "inline-block absolute top-0 left-0 rotate-90 w-64 pl-16": isCollapsed }
                    )}
                >
                    {name}
                </span>

                <Tooltip label={`${isCollapsed ? "Expand" : "Collapse"} swimlane`}>
                    <button
                        className={classNames(
                            "absolute pointer",
                            { "right-2": !isCollapsed, "right-3 top-2": isCollapsed }
                        )}
                        onClick={() => dispatch(isCollapsed ? expandSwimlane(id) : collapseSwimlane(id))}
                    >
                        <Icon className="rotate-90" />
                    </button>
                </Tooltip>
            </div>
            <Droppable droppableId={`Swimlane/swimlane#${id}`} isDropDisabled={isCollapsed}>
                {({ placeholder, innerRef, droppableProps }, { isDraggingOver }) => (
                    <div
                        ref={innerRef}
                        {...droppableProps}
                        className={classNames("px-3 pt-3 overflow-y-auto h-full", {
                            "bg-blue-50": isDraggingOver,
                            "hidden": isCollapsed
                        })}
                        style={{
                            ...droppableProps.style,
                            height: `calc(100vh - ${heightOffset}px)`
                        }}
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

export default Swimlane;
