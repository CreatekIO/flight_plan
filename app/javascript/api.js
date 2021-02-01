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
    }).then(response =>
        response.status < 500
            ? response.json()
            : Promise.reject(new Error("Oops! Something went wrong!"))
    );

const post = createApiFunction("POST");
const put = createApiFunction("PUT");
const patch = createApiFunction("PATCH");

const formatURL = (url, params) => url.replace(/:([a-z_]+)/gi, (_, key) => params[key]);

const {
    boardURL,
    nextActionsURL,
    sluggedTicketURL,
    repoLabelsURL,
    createTicketMoveURL,
    createTicketURL,
    ticketLabellingURL
} = flightPlanConfig.api;

export const getBoard = () => get(boardURL);
export const getBoardNextActions = () => get(nextActionsURL);
export const getSwimlaneTickets = url => get(url);
export const getBoardTicket = url => get(url);
export const getBoardTicketFromSlug = (slug, number) => get(
    formatURL(sluggedTicketURL, { slug, number })
);
export const getRepoLabels = id => get(formatURL(repoLabelsURL, { id }));

export const createTicketMove = (boardTicketId, swimlaneId, indexInSwimlane) =>
    post(formatURL(createTicketMoveURL, { boardTicketId }), {
        board_ticket: {
            swimlane_id: swimlaneId,
            swimlane_position: indexInSwimlane
        }
    });

export const createTicket = ({ repo_id, swimlane, title, description }) =>
    post(createTicketURL, {
        ticket: { repo_id, swimlane, title, description }
    });

export const updateTicketLabels = (boardTicketId, changes) => patch(
    formatURL(ticketLabellingURL, { boardTicketId }),
    { labelling: changes }
);
