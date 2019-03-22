import { normalize, schema } from "normalizr";


export const pullRequest = new schema.Entity("pullRequests");

export const repo = new schema.Entity("repos", { pull_requests: [pullRequest] });

export const ticket = new schema.Entity("tickets", { repo });

export const boardTicket = new schema.Entity("boardTickets", {
    ticket,
    pull_requests: [pullRequest]
});

export const swimlane = new schema.Entity("swimlanes", { board_tickets: [boardTicket] });

export const board = new schema.Entity("boards", { swimlanes: [swimlane] });
