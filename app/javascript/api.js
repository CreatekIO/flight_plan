const get = url => fetch(url).then(response => response.json());

const createApiFunction = method => (url, body) =>
    fetch(url, {
        body: JSON.stringify(body),
        method: method,
        headers: {
            'X-CSRF-Token': window.Rails.csrfToken(),
            'Content-Type': 'application/json'
        },
        // Send cookies with request
        credentials: 'same-origin'
    }).then(
        response =>
            response.status < 500
                ? response.json()
                : Promise.reject(new Error('Oops! Something went wrong!'))
    );

const post = createApiFunction('POST');
const put = createApiFunction('PUT');

const formatURL = (url, params) =>
    url.replace(/:([^\/]+)/i, (_, key) => params[key]);

export const getBoard = () => get(flightPlanConfig.api.boardURL);
export const getBoardNextActions = () =>
    get(flightPlanConfig.api.nextActionsURL);
export const getSwimlaneTickets = url => get(url);
export const getBoardTicket = url => get(url);

export const createTicketMove = (boardTicketId, swimlaneId, indexInSwimlane) =>
    post(
        formatURL(flightPlanConfig.api.createTicketMoveURL, { boardTicketId }),
        {
            board_ticket: {
                swimlane_id: swimlaneId,
                swimlane_position: indexInSwimlane
            }
        }
    );

export const createTicket = ticketAttributes => {
    post(formatURL(flightPlanConfig.api.createTicketURL), {
        ticket: {
            repo_id: ticketAttributes['repo_id'],
            title: ticketAttributes['title'],
            description: ticketAttributes['description']
        }
    });
};
