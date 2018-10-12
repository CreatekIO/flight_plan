import React, { PureComponent } from "react";
import { connect } from "react-redux";
import { Droppable } from "react-beautiful-dnd";

import TicketCard from "./TicketCard";

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

const Swimlane = ({ id, name, board_tickets, display_duration }) => (
    <div className="swimlane">
        <div className="ui small grey center aligned header swimlane-header">{name}</div>
        <Droppable droppableId={`swimlane-${id}`}>
            {(provided, snapshot) => (
                <div
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                    className="body"
                >
                    <TicketList
                        display_duration={display_duration}
                        board_tickets={board_tickets}
                    />
                    {provided.placeholder}
                </div>
            )}
        </Droppable>
    </div>
);

const mapStateToProps = (_, { id }) => ({ entities }) => entities.swimlanes[id];

export default connect(mapStateToProps)(Swimlane);
