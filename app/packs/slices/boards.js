import { createSlice } from "@reduxjs/toolkit";
import { normalize, schema } from "normalizr";

import { createRequestThunk, upsert } from "./utils";

const { Entity } = schema;

const boardSchema = new Entity("boards", {
    swimlanes: [
        new Entity("swimlanes", {
            board_tickets: [
                new Entity("boardTickets", {
                    ticket: new Entity("tickets", {
                        repo: new Entity("repos")
                    }),
                    milestone: new Entity("milestones"),
                    labels: [new Entity("labels")],
                    pull_requests: [
                        new Entity("pullRequests")
                    ]
                })
            ]
        })
    ]
});

const processNormalisedResponse = payload => {
    Object.values(payload.boardTickets).forEach(boardTicket => {
        delete boardTicket.latest_timesheet; // not yet used

        const {
            assignments,
            labels,
            milestone,
            pull_requests,
            ...ticket
        } = payload.tickets[boardTicket.ticket];

        boardTicket.labels = labels;
        if (milestone) boardTicket.milestone = milestone;
        boardTicket.pull_requests = pull_requests;

        boardTicket.assignees = assignments.map(id => {
            const { username, remote_id } = payload.ticketAssignments[id];
            return { username, remote_id };
        });

        payload.tickets[ticket.id] = ticket;
    });

    delete payload.ticketAssignments;
    delete payload.timesheets;

    return payload;
};

const isAlreadyNormalised = payload => !("id" in payload);

export const fetchBoard = createRequestThunk.get({
    name: "boards/fetch",
    path: id => `/boards/${id}.json`,
    process: (payload, id, { extra: { get }}) => {
        if (isAlreadyNormalised(payload)) return {
            boardId: id,
            entities: processNormalisedResponse(payload)
        }

        const { result, entities } = normalize(payload, boardSchema);
        return { boardId: result, entities };
    }
});

const { reducer } = createSlice({
    name: "boards",
    initialState: {}
});

export default reducer;
