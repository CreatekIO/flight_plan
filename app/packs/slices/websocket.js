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

const upsertPrepare = ({ meta, payload }) => {
    const action = { meta, payload };

    if ("entities" in payload) return action;

    action.payload = { entities: payload };
    return action;
}

const identity = action => action;

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

export const ticketRetitled = createAction("ws/ticket/title_changed", upsertPrepare);
export const ticketLabelled = createAction("ws/ticket/labelled", identity);
export const ticketUnlabelled = createAction("ws/ticket/unlabelled", identity);
export const ticketAssigned = createAction("ws/ticket/assigned", identity);
export const ticketUnassigned = createAction("ws/ticket/unassigned", identity);

const handlers = [
    ticketWasMoved,
    ticketRetitled,
    ticketLabelled,
    ticketUnlabelled,
    ticketAssigned,
    ticketUnassigned
];

const middleware = _store => next => action => {
    const handler = handlers.find(handler => handler.match(action));
    if (!handler) return next(action);

    if (action.meta && action.meta.userId === flightPlanConfig.currentUser.id) return;

    return next(handler(action));
}

export default middleware;
