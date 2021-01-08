import { normalize, schema } from "normalizr";

export const pullRequest = new schema.Entity("pullRequests");

// Separate schema to avoid circular references
export const pullRequestWithRepo = new schema.Entity("pullRequests", {
    repo: new schema.Entity("repos")
});

export const milestone = new schema.Entity("milestones");

export const label = new schema.Entity("labels");

export const comment = new schema.Entity("comments");

export const repo = new schema.Entity("repos", { pull_requests: [pullRequest] });

export const ticket = new schema.Entity("tickets", { repo });

export const boardTicket = new schema.Entity("boardTickets", {
    ticket,
    milestone,
    labels: [label],
    pull_requests: [pullRequestWithRepo],
    comments: [comment]
});

export const swimlane = new schema.Entity("swimlanes", { board_tickets: [boardTicket] });

export const board = new schema.Entity("boards", { swimlanes: [swimlane] });
