import React, { PureComponent } from "react";
import { connect } from "react-redux";
import { Droppable } from "react-beautiful-dnd";
import classNames from "classnames";
import Octicon, { Fold, Unfold } from "@githubprimer/octicons-react";

import TicketCard from "./TicketCard";

import {
    loadSwimlaneTickets,
    collapseSwimlane,
    expandSwimlane
} from "../action_creators";

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
    <div className={classNames("swimlane", { "is-collapsed": isCollapsed })}>
        <div className="ui small grey center aligned header swimlane-header">
            <span className="swimlane-header-text">{name}</span>
            {isCollapsed ? (
                <button
                    className="swimlane-toggle-btn"
                    onClick={() => expandSwimlane(id)}
                >
                    <Octicon icon={Unfold} />
                </button>
            ) : (
                <button
                    className="swimlane-toggle-btn"
                    onClick={() => collapseSwimlane(id)}
                >
                    <Octicon icon={Fold} />
                </button>
            )}
        </div>
        <Droppable droppableId={`Swimlane#swimlane-${id}`} isDropDisabled={isCollapsed}>
            {(provided, snapshot) => (
                <div
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                    className={`body ${
                        snapshot.isDraggingOver ? "is-dragging-over" : ""
                    }`}
                >
                    {isCollapsed || (
                        <React.Fragment>
                            <TicketList
                                display_duration={display_duration}
                                board_tickets={board_tickets}
                            />
                            {provided.placeholder}
                            {all_board_tickets_loaded || (
                                <button
                                    className="fluid basic ui button"
                                    onClick={() =>
                                        loadSwimlaneTickets(id, next_board_tickets_url)
                                    }
                                    disabled={loading_board_tickets}
                                >
                                    {loading_board_tickets ? "Loading..." : "Load more"}
                                </button>
                            )}
                        </React.Fragment>
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
