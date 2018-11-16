const rootReducer = (state = {}, action) => {
    switch (action.type) {
        case "RESET":
            return {};
        default:
            return state;
    }
};

export default rootReducer;
