import { createSlice, isFulfilled } from "@reduxjs/toolkit";
import { createRequestThunk } from "./utils";

import { updateLabelsForTicket } from "./board_tickets";
import { ticketLabelled } from "./websocket";
import { upsert } from "./utils";

export const fetchLabelsForRepo = createRequestThunk.get({
    name: "labels/fetchForRepo",
    path: id => `/repos/${id}/labels`
});

const hasLabelsPayload = isFulfilled(fetchLabelsForRepo, updateLabelsForTicket);

const slice = createSlice({
    name: "labels",
    initialState: {},
    extraReducers: builder => {
        builder.addCase(ticketLabelled, (state, { payload: { label }}) =>
            upsert(state, [label])
        );
        builder.addMatcher(hasLabelsPayload, (state, { payload }) =>
            upsert(state, payload)
        );
    }
});

export default slice.reducer;
