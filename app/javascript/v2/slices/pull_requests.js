import { createSlice } from "@reduxjs/toolkit";
import { normalize, schema } from "normalizr";

import { createRequestThunk } from "./utils";

const nextActionsSchema = [
    new schema.Entity("repos", {
        pull_requests: [
            new schema.Entity("pullRequests")
        ]
    })
];

// Handled in `entities` slice reducer
export const fetchNextActions = createRequestThunk({
    name: "pullRequests/fetchNextActions",
    path: id => `/boards/${id}/next_actions`,
    process: payload => {
        const { entities } = normalize(payload, nextActionsSchema);
        return { entities };
    }
});

const { reducer } = createSlice({
    name: "pullRequests",
    initialState: {}
});

export default reducer;
