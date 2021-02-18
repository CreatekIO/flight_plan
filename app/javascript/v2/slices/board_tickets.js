import { createSlice } from "@reduxjs/toolkit";

import { createRequestThunk } from "./utils";

const getIn = (object, path, notFound = null) => {
    const parts = Array.isArray(path) ? path : path.split(".");
    let current = object;

    for (const part of parts) {
        if (current === undefined) return notFound;
        current = current[part];
    }

    return current;
};

const idsToNames = (ids, state) =>
    ids.map(id => getIn(state, `entities.labels.${id}.name`)).filter(Boolean);

export const updateLabelsForTicket = createRequestThunk.patch({
    name: "boardTickets/updateLabels",
    path: ({ id }) => `/${flightPlanConfig.api.htmlBoardURL}/board_tickets/${id}/labels`,
    body: ({ add: idsToAdd, remove: idsToRemove }, { getState }) => ({
        labelling: {
            add: idsToNames(idsToAdd, getState()),
            remove: idsToNames(idsToRemove, getState())
        }
    }),
    condition: ({ add, remove }) => Boolean(add.length || remove.length)
});

const makeLabelChanges = (labels, { add, remove }) => {
    add.forEach(id => labels.includes(id) || labels.push(id));

    remove.forEach(id => {
        const index = labels.indexOf(id);
        if (index > -1) labels.splice(index, 1);
    });
};

const { reducer } = createSlice({
    name: "boardTickets",
    // This won't be used since V1 will set it first, but set it for
    // the time when we are no longer using V1
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
        }
    }
});

export default reducer;
