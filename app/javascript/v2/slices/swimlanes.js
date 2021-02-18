import { createSlice, current } from "@reduxjs/toolkit";

import { rehydrateStore, upsert } from "./utils";

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
