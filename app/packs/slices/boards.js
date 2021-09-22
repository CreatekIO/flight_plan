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

export const fetchBoard = createRequestThunk.get({
    name: "boards/fetch",
    path: id => `/boards/${id}.json`,
    process: payload => {
        const { result, entities } = normalize(payload, boardSchema);
        return { boardId: result, entities };
    }
});

const { reducer } = createSlice({
    name: "boards",
    initialState: {}
});

export default reducer;
