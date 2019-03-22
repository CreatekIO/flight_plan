const get = url => fetch(url).then(response => response.json());

const createApiFunction = method => (url, body) =>
    fetch(url, {
        body: JSON.stringify(body),
        method: method,
        headers: {
            "X-CSRF-Token": window.Rails.csrfToken(),
            "Content-Type": "application/json"
        },
        // Send cookies with request
        credentials: "same-origin"
    }).then(
        response =>
            response.status < 500
                ? response.json()
                : Promise.reject(new Error("Oops! Something went wrong!"))
    );

const post = createApiFunction("POST");
const put = createApiFunction("PUT");

export const getBoard = () => get(flightPlanConfig.api.boardURL);
export const getBoardNextActions = () => get(flightPlanConfig.api.nextActionsURL);
