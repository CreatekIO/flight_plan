import React from "react";
import { connect } from "react-redux";

import TicketCard from "./TicketCard";

const Swimlane = ({ name, board_tickets, display_duration }) => {
    return (
        <div className="swimlane">
            <div className="ui small grey center aligned header swimlane-header">
                {name}
            </div>
            <div className="body">
                {board_tickets.map(boardTicketId => (
                    <TicketCard
                        display_duration={display_duration}
                        key={boardTicketId}
                        id={boardTicketId}
                    />
                ))}
            </div>
        </div>
    );
};

const mapStateToProps = ({ entities }, ownProps) => entities.swimlanes[ownProps.id];

export default connect(mapStateToProps)(Swimlane);
