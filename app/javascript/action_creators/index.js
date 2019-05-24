import {
    getBoard,
    getBoardNextActions,
    getSwimlaneTickets,
    createTicketMove,
    getBoardTicket,
    createTicket
} from '../api';

const extractId = identifier => identifier.split('-').reverse()[0];

const checkForErrors = data =>
    new Promise(
        (resolve, reject) =>
            data.error || data.errors ? reject(new Error()) : resolve(data)
    );

export const loadBoard = () => dispatch =>
    getBoard().then(board => dispatch(boardLoaded(board)));

export const loadNextActions = () => dispatch =>
    getBoardNextActions().then(repos => dispatch(nextActionsLoaded(repos)));

export const loadSwimlaneTickets = (swimlaneId, url) => dispatch => {
    dispatch(swimlaneTicketsLoading(swimlaneId));

    return getSwimlaneTickets(url).then(swimlane =>
        dispatch(swimlaneTicketsLoaded(swimlane))
    );
};

export const loadFullTicket = (id, url) => dispatch => {
    dispatch(fullTicketLoading(id));

    return getBoardTicket(url).then(boardTicket =>
        dispatch(fullTicketLoaded(boardTicket))
    );
};

export const ticketDragged = ({
    source,
    destination,
    draggableId
}) => dispatch => {
    const boardTicketId = extractId(draggableId);

    dispatch(ticketMoved({ source, destination }));

    return createTicketMove(
        boardTicketId,
        extractId(destination.droppableId),
        destination.index
    )
        .then(checkForErrors)
        .then(response => dispatch(boardTicketLoaded(response)))
        .catch(() =>
            dispatch(
                // Move TicketCard back to where it came from
                ticketMoved({
                    source: destination,
                    destination: source,
                    boardTicketId
                })
            )
        );
};

export const ticketMoved = ({ source, destination, boardTicketId }) => ({
    type: 'TICKET_MOVED',
    payload: {
        boardTicketId,
        sourceId: extractId(source.droppableId),
        sourceIndex: source.index,
        destinationId: extractId(destination.droppableId),
        destinationIndex: destination.index
    }
});

export const ticketCreated = ticketAttributes => {
    createTicket(ticketAttributes);
};

export const boardLoaded = board => ({
    type: 'BOARD_LOAD',
    payload: board
});

export const nextActionsLoaded = repos => ({
    type: 'NEXT_ACTIONS_LOADED',
    payload: repos
});

export const swimlaneTicketsLoading = swimlaneId => ({
    type: 'SWIMLANE_TICKETS_LOADING',
    payload: { swimlaneId }
});

export const swimlaneTicketsLoaded = swimlane => ({
    type: 'SWIMLANE_TICKETS_LOADED',
    payload: swimlane
});

export const boardTicketLoaded = boardTicket => ({
    type: 'BOARD_TICKET_LOADED',
    payload: boardTicket
});

export const fullTicketLoading = boardTicketId => ({
    type: 'FULL_TICKET_LOADING',
    payload: { boardTicketId }
});

export const fullTicketLoaded = boardTicket => ({
    type: 'FULL_TICKET_LOADED',
    payload: boardTicket
});
