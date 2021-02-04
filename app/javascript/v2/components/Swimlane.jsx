import React, { Fragment, PureComponent } from "react";
import { connect } from "react-redux";
import { Droppable } from "react-beautiful-dnd";
import classNames from "classnames";
import Octicon, { Fold, Unfold } from "@githubprimer/octicons-react";

import TicketCard from "./TicketCard";

import {
    loadSwimlaneTickets,
    collapseSwimlane,
    expandSwimlane
} from "../../action_creators";

// FIXME: implement
const Popup = ({ trigger }) => trigger;

// Performance optimisation as recommended by
// https://github.com/atlassian/react-beautiful-dnd#recommended-droppable-performance-optimisation
class TicketList extends PureComponent {
    render() {
        return this.props.board_tickets.map((id, index) => (
            <TicketCard
                display_duration={this.props.display_duration}
                index={index}
                key={id}
                id={id}
            />
        ));
    }
}

const Swimlane = ({
    id,
    name,
    isCollapsed,
    board_tickets,
    display_duration,
    next_board_tickets_url,
    loading_board_tickets,
    all_board_tickets_loaded,
    loadSwimlaneTickets,
    collapseSwimlane,
    expandSwimlane
}) => (
    <div
        className={classNames(
            "flex-none border-l-2 border-gray-200 bg-gray-50 transition-all duration-200 ease-out text-gray-500",
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
            >{name}</span>
            <Popup
                trigger={
                    <button
                        className={classNames(
                            "absolute pointer",
                            { "right-2": !isCollapsed, "right-3 top-2": isCollapsed }
                        )}
                        onClick={() =>
                            isCollapsed ? expandSwimlane(id) : collapseSwimlane(id)
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
                                display_duration={display_duration}
                                board_tickets={board_tickets}
                            />
                            {placeholder}
                            {all_board_tickets_loaded || (
                                <button
                                    className="w-full border border-gray-300 p-1 rounded text-gray-500 text-sm hover:bg-white mb-3"
                                    onClick={() =>
                                        loadSwimlaneTickets(id, next_board_tickets_url)
                                    }
                                    disabled={loading_board_tickets}
                                >
                                    {loading_board_tickets ? "Loading..." : "Load more"}
                                </button>
                            )}
                        </Fragment>
                    )}
                </div>
            )}
        </Droppable>
    </div>
);

const mapStateToProps = (_, { id }) => ({ entities }) => entities.swimlanes[id];

export default connect(
    mapStateToProps,
    { loadSwimlaneTickets, collapseSwimlane, expandSwimlane }
)(Swimlane);
