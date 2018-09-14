import React from "react";

export default function TicketCard(props) {
    return (
        <div className="ui card">
            <div className="content">{props.ticket.remote_number}</div>
        </div>
    );
}
