import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";

import { getRepoLabels } from "../../api";

export const fetchLabelsForRepo = createAsyncThunk(
    "labels/fetchForRepo",
    repoId => getRepoLabels(repoId)
);

const upsert = (state, records) => {
    records.forEach(record => {
        const { id } = record;
        state[id] = { ...state[id], ...record };
    });
}

const slice = createSlice({
    name: "labels",
    // This won't be used since V1 will set it first, but set it for
    // the time when we are no longer using V1
    initialState: {},
    extraReducers: {
        [fetchLabelsForRepo.fulfilled]: (state, action) => {
            upsert(state, action.payload);
        }
    }
});

export default slice.reducer;
