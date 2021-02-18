import { createAsyncThunk } from "@reduxjs/toolkit";

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
