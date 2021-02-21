import { createAction, isAnyOf } from "@reduxjs/toolkit";
import { normalize, schema } from "normalizr";

const { Entity } = schema;

const boardTicketSchema = new Entity("boardTickets", {
    ticket: new Entity("tickets", {
        repo: new Entity("repos")
    }),
    milestone: new Entity("milestones"),
    labels: [new Entity("labels")],
    pull_requests: [new Entity("pullRequests")]
});

export const ticketWasMoved = createAction(
    "ws/TICKET_WAS_MOVED",
    ({ payload: { boardTicket, destinationId, destinationIndex }}) => ({
        payload: {
            to: { swimlaneId: destinationId, index: destinationIndex },
            entities: normalize(boardTicket, boardTicketSchema).entities,
            boardTicketId: boardTicket.id
        }
    })
);

const handlers = [ticketWasMoved];

const middleware = _store => next => action => {
    const handler = handlers.find(handler => handler.match(action));
    if (!handler) return next(action);

    return next(handler(action));
}

export default middleware;
