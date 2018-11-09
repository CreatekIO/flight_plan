import React from "react";

import TicketCard from "./TicketCard";

export default function Swimlane(props) {
    const { name, board_tickets, display_duration } = props;

    return (
        <div className="swimlane">
            <div className="ui small grey center aligned header swimlane-header">
                {name}
            </div>
            <div className="body">
                {board_tickets.map(board_ticket => (
                    <TicketCard
                        {...board_ticket}
                        display_duration={display_duration}
                        key={board_ticket.id}
                    />
                ))}
            </div>
        </div>
    );
}
