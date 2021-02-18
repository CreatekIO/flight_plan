import { createSlice, createAsyncThunk, isFulfilled } from "@reduxjs/toolkit";

import { updateLabelsForTicket } from "./board_tickets";

export const fetchLabelsForRepo = createAsyncThunk(
    "labels/fetchForRepo",
    (id, { extra: { get }}) => get(`/repos/${id}/labels`)
);

const upsert = (state, records) => {
    records.forEach(record => {
        const { id } = record;
        state[id] = { ...state[id], ...record };
    });
}

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
