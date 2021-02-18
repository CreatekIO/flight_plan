import { createSlice, current } from "@reduxjs/toolkit";

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
