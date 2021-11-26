import { createSlice } from "@reduxjs/toolkit";
import { createRequestThunk } from "./utils";

export const fetchAssigneesForRepo = createRequestThunk.get({
    name: "repos/fetchAssignees",
    path: id => `/repos/${id}/assignees`
});

const slice = createSlice({
    name: "repos",
    initialState: {},
    extraReducers: {
        [fetchAssigneesForRepo.fulfilled]: (state, { payload, meta }) => {
            const repo = state[meta.arg];
            if (!repo) return;

            repo.availableAssignees = payload;
        }
    }
});

export default slice.reducer;
