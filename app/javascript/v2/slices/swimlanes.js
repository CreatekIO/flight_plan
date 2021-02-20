import { createSlice, current } from "@reduxjs/toolkit";
import { normalize, schema } from "normalizr";

import { createRequestThunk, rehydrateStore, upsert } from "./utils";

const { Entity } = schema;

const boardTicketSchema = [
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
];

export const fetchSwimlaneTickets = createRequestThunk.get({
    name: "swimlanes/fetchBoardTickets",
    path: url => url,
    process: ({ board_tickets, ...swimlane }) => {
        const { result, entities } = normalize(board_tickets, boardTicketSchema);

        return {
            swimlaneId: swimlane.id,
            boardTicketIds: result,
            entities: { ...entities, swimlanes: { [swimlane.id]: swimlane }}
        };
    }
});

const {
    reducer,
    actions: { collapse, expand }
} = createSlice({
    name: "swimlanes",
    initialState: {},
    reducers: {
        collapse: (state, { payload: id }) => {
            const swimlane = state[id];
            if (swimlane) swimlane.isCollapsed = true;
        },
        expand: (state, { payload: id }) => {
            const swimlane = state[id];
            if (swimlane) swimlane.isCollapsed = false;
        }
    },
    extraReducers: {
        [rehydrateStore]: (state, { payload }) => {
            const changes = [];

            for (const key in payload) {
                const match = key.match(/^swimlane:(\d+):collapsed$/);
                if (!match) continue;

                changes.push({ id: parseInt(match[1], 10), isCollapsed: true });
            }

            upsert(state, changes);
        },
        [fetchSwimlaneTickets.fulfilled]: (state, { payload: { swimlaneId: id, boardTicketIds }}) => {
            const swimlane = state[id];

            swimlane.board_tickets = [
                ...swimlane.board_tickets,
                ...boardTicketIds
            ];
        }
    }
});

export const collapseSwimlane = id => (dispatch, _, { addToStorage }) => {
    addToStorage(`swimlane:${id}:collapsed`, 1);
    return dispatch(collapse(id));
}

export const expandSwimlane = id => (dispatch, _, { removeFromStorage }) => {
    removeFromStorage(`swimlane:${id}:collapsed`);
    return dispatch(expand(id));
}

export default reducer;
