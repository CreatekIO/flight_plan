import { createSlice } from "@reduxjs/toolkit";
import { createRequestThunk } from "./utils";

export const fetchAssigneesForRepo = createRequestThunk.get({
    name: "repos/fetchAssignees",
    path: id => `/repos/${id}/assignees`
});

export const isRepoDisabled = ({ uses_app: usesApp }) =>
    usesApp && !flightPlanConfig.currentUser.signedInWithApp;

export const isRepoEnabled = repo => !isRepoDisabled(repo);

const slice = createSlice({
    name: "repos",
    initialState: {},
    extraReducers: ({ addCase }) => {
        addCase(fetchAssigneesForRepo.fulfilled, (state, { payload, meta }) => {
            const repo = state[meta.arg];
            if (!repo) return;

            repo.availableAssignees = payload;
        });
    }
});

export default slice.reducer;
