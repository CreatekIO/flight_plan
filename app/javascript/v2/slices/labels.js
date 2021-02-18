import { createSlice, isFulfilled } from "@reduxjs/toolkit";
import { createRequestThunk } from "./utils";

import { updateLabelsForTicket } from "./board_tickets";
import { upsert } from "./utils";

export const fetchLabelsForRepo = createRequestThunk.get({
    name: "labels/fetchForRepo",
    path: id => `/repos/${id}/labels`
});

const hasLabelsPayload = isFulfilled(fetchLabelsForRepo, updateLabelsForTicket);

const slice = createSlice({
    name: "labels",
    // This won't be used since V1 will set it first, but set it for
    // the time when we are no longer using V1
    initialState: {},
    extraReducers: builder => {
        builder.addMatcher(hasLabelsPayload, (state, { payload }) =>
            upsert(state, payload)
        );
    }
});

export default slice.reducer;
