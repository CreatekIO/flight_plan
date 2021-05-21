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
    ({ meta, payload: { boardTicket, destinationId, destinationIndex }}) => ({
        meta,
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

    if (action.meta && action.meta.userId === flightPlanConfig.currentUser.id) return;

    return next(handler(action));
}

export default middleware;