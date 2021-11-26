import { createSlice } from "@reduxjs/toolkit";
import { normalize, schema } from "normalizr";

import { createRequestThunk } from "./utils";
import {
    ticketLabelled,
    ticketUnlabelled,
    ticketAssigned,
    ticketUnassigned
} from "./websocket";

const { htmlBoardURL } = flightPlanConfig.api;
const { Entity } = schema;

const baseSchema = new Entity("boardTickets", {
    ticket: new Entity("tickets", {
        repo: new Entity("repos")
    }),
    milestone: new Entity("milestones"),
    labels: [new Entity("labels")],
    pull_requests: [new Entity("pullRequests")]
});

const fullSchema = new Entity("boardTickets", {
    ...baseSchema.schema,
    comments: [new Entity("comments")],
    pull_requests: [
        new Entity("pullRequests", {
            repo: new Entity("repos")
        })
    ]
});

export const fetchTicket = createRequestThunk.get({
    name: 'boardTickets/fetch',
    path: ({ slug, number }) => `${htmlBoardURL}/tickets/${slug}/${number}`,
    process: payload => {
        const { result, entities } = normalize(payload, fullSchema);
        return { entities, boardTicketId: result };
    }
});

export const moveTicket = createRequestThunk.post({
    name: 'boardTickets/move',
    path: ({ boardTicketId }) =>
        `${htmlBoardURL}/board_tickets/${boardTicketId}/moves`,
    body: ({ boardTicketId, to: { swimlaneId, index }}) => ({
        board_ticket: {
            swimlane_id: swimlaneId,
            swimlane_position: index
        }
    }),
    process: payload => {
        const { result, entities } = normalize(payload, baseSchema);
        return { entities, boardTicketId: result };
    }
});

const getIn = (object, path, notFound = null) => {
    const parts = Array.isArray(path) ? path : path.split(".");
    let current = object;

    for (const part of parts) {
        if (current === undefined) return notFound;
        current = current[part];
    }

    return current;
};

const labelIdsToNames = (ids, state) =>
    ids.map(id => getIn(state, `entities.labels.${id}.name`)).filter(Boolean);

export const updateLabelsForTicket = createRequestThunk.patch({
    name: "boardTickets/updateLabels",
    path: ({ id }) => `${htmlBoardURL}/board_tickets/${id}/labels`,
    body: ({ add: idsToAdd, remove: idsToRemove }, { getState }) => ({
        labelling: {
            add: labelIdsToNames(idsToAdd, getState()),
            remove: labelIdsToNames(idsToRemove, getState())
        }
    }),
    condition: ({ add, remove }) => Boolean(add.length || remove.length)
});

export const updateAssigneesForTicket = createRequestThunk.patch({
    name: "boardTickets/updateAssignees",
    path: ({ id }) => `${htmlBoardURL}/board_tickets/${id}/assignees`,
    body: ({ add, remove }) => ({
        assignment: {
            add: add.map(({ username }) => username),
            remove: remove.map(({ username }) => username)
        }
    }),
    condition: ({ add, remove }) => Boolean(add.length || remove.length)
});

const makeLabelChanges = (labels, { add = [], remove = [] }) => {
    add.forEach(id => labels.includes(id) || labels.push(id));

    remove.forEach(id => {
        const index = labels.indexOf(id);
        if (index > -1) labels.splice(index, 1);
    });
};

const makeAssigneeChanges = (boardTicket, { add = [], remove = [] }) => {
    add.forEach(({ remote_id: newId, username }) => {
        if (!boardTicket.assignees) {
            boardTicket.assignees = [{ remote_id: newId, username }];
            return
        }

        const existing = boardTicket.assignees.find(
            ({ remote_id }) => newId === remote_id
        );

        if (existing) return;

        boardTicket.assignees.push({ remote_id: newId, username });
    });

    if (!boardTicket.assignees) return;

    remove.forEach(({ remote_id: removedId }) => {
        const index = boardTicket.assignees.findIndex(
            ({ remote_id }) => removedId === remote_id
        );

        if (index > -1) boardTicket.assignees.splice(index, 1);
    });
};

const withBoardTicket = callback => (state, { payload }) => {
    const { boardTicketId } = payload;
    const boardTicket = state[boardTicketId];
    if (!boardTicket) return;

    callback({ boardTicket, ...payload });
}

const { reducer } = createSlice({
    name: "boardTickets",
    initialState: {},
    extraReducers: {
        [updateLabelsForTicket.pending]: (state, { meta }) => {
            const { id, add, remove } = meta.arg;
            makeLabelChanges(state[id].labels, { add, remove });
        },
        [updateLabelsForTicket.fulfilled]: (state, { payload, meta }) => {
            const { id } = meta.arg;
            state[id].labels = payload.map(({ id }) => id);
        },
        [updateLabelsForTicket.rejected]: (state, { meta }) => {
            const { id, add, remove } = meta.arg;
            makeLabelChanges(state[id].labels, { add: remove, remove: add });
        },
        [ticketLabelled]: withBoardTicket(({ boardTicket, label }) => {
            makeLabelChanges(boardTicket.labels, { add: [label.id] });
        }),
        [ticketUnlabelled]: withBoardTicket(({ boardTicket, labelId }) => {
            makeLabelChanges(boardTicket.labels, { remove: [labelId] });
        }),
        [updateAssigneesForTicket.pending]: (state, { meta }) => {
            const { id, add, remove } = meta.arg;
            makeAssigneeChanges(state[id], { add, remove });
        },
        [updateAssigneesForTicket.fulfilled]: (state, { payload, meta }) => {
            const { id } = meta.arg;
            state[id].assignees = payload.map(
                ({ username, remote_id }) => ({ username, remote_id })
            );
        },
        [updateAssigneesForTicket.rejected]: (state, { meta }) => {
            const { id, add, remove } = meta.arg;
            makeAssigneeChanges(state[id], { add: remove, remove: add });
        },
        [ticketAssigned]: withBoardTicket(({ boardTicket, assignee }) => {
            makeAssigneeChanges(boardTicket, { add: [assignee] });
        }),
        [ticketUnassigned]: withBoardTicket(({ boardTicket, assignee }) => {
            makeAssigneeChanges(boardTicket, { remove: [assignee] });
        })
    }
});

export default reducer;
