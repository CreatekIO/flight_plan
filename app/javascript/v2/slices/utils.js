import { createAction, createAsyncThunk } from "@reduxjs/toolkit";

export const createRequestThunk = ({
    name,
    method = "get",
    path,
    body,
    condition
}) => createAsyncThunk(
    name,
    (arg, thunkArg) => thunkArg.extra[method.toLowerCase()](
        path(arg, thunkArg),
        body && body(arg, thunkArg)
    ).then(json => {
        const errorData = json.error || json.errors;
        return errorData ? thunkArg.rejectWithValue(errorData) : json;
    }),
    { condition }
);

for (const method of ["get", "post", "patch", "put"]) {
    createRequestThunk[method] = args => createRequestThunk({ ...args, method });
}

export const upsert = (state, records) => {
    records.forEach(record => {
        const { id } = record;
        state[id] = { ...state[id], ...record };
    });
}

export const rehydrateStore = createAction(
    "flightplan/rehydrate",
    () => {
        const payload = {};

        try {
            let size = localStorage.length;

            while (size--) {
                const key = localStorage.key(size);
                payload[key] = localStorage.getItem(key);
            }
        } catch(error) {
            if (process.env.NODE_ENV !== "production") console.warn(error);
        }

        return { payload };
    }
);
