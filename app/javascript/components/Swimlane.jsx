import React, { PureComponent } from "react";
import { connect } from "react-redux";
import { Droppable } from "react-beautiful-dnd";

import TicketCard from "./TicketCard";

import { loadSwimlaneTickets } from "../action_creators";

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
    board_tickets,
    display_duration,
    next_board_tickets_url,
    loading_board_tickets,
    all_board_tickets_loaded,
    loadSwimlaneTickets
}) => (
    <div className="swimlane">
        <div className="ui small grey center aligned header swimlane-header">{name}</div>
        <Droppable droppableId={`swimlane-${id}`}>
            {(provided, snapshot) => (
                <div
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                    className={`body ${
                        snapshot.isDraggingOver ? "is-dragging-over" : ""
                    }`}
                >
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
                </div>
            )}
        </Droppable>
    </div>
);

const mapStateToProps = (_, { id }) => ({ entities }) => entities.swimlanes[id];

export default connect(
    mapStateToProps,
    { loadSwimlaneTickets }
)(Swimlane);
