import {
    getBoard,
    getBoardNextActions,
    getSwimlaneTickets,
    createTicketMove,
    getBoardTicket,
    getBoardTicketFromSlug,
    createTicket
} from '../api';

import { getBoardUpdates } from '../websocket';

const extractId = identifier => identifier.split('-').reverse()[0];

const checkForErrors = data =>
    new Promise(
        (resolve, reject) =>
            data.error || data.errors ? reject(new Error()) : resolve(data)
    );

const mergeInCollapsedStateOfSwimlanes = board =>
    new Promise((resolve, reject) => {
        try {
            board.swimlanes.forEach(swimlane => {
                let isCollapsed = false;

                try {
                    isCollapsed = !!localStorage.getItem(
                        `swimlane:${swimlane.id}:collapsed`
                    );
                } catch (err) {
                    console.warn(error);
                }

                swimlane.isCollapsed = isCollapsed;
            });

            resolve(board);
        } catch (err) {
            reject(err);
        }
    });

export const loadBoard = () => dispatch =>
    getBoard()
        .then(mergeInCollapsedStateOfSwimlanes)
        .then(board => dispatch(boardLoaded(board)));

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

export const loadFullTicketFromSlug = (slug, number) => dispatch => {
    return getBoardTicketFromSlug(slug, number).then(boardTicket =>
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

const conditionalDispatch = dispatch => action => {
    const { meta } = action;

    if (meta && meta.userId !== flightPlanConfig.currentUser.id) {
        return dispatch(action);
    }
};

export const subscribeToBoard = id => dispatch =>
    getBoardUpdates(id, conditionalDispatch(dispatch));

export const ticketCreated = ticketAttributes => dispatch => {
    return createTicket(ticketAttributes)
        .then(
            response => dispatch(ticketCreation(response)),
            reason => {
                console.warn(reason);
            }
        )
        .catch(
            error =>
                function() {
                    console.warn(error);
                }
        );
};

export const ticketCreation = ticketAttributes => ({
    type: 'TICKET_CREATED',
    payload: ticketAttributes
});

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

export const collapseSwimlane = swimlaneId => ({
    type: 'COLLAPSE_SWIMLANE',
    payload: { swimlaneId }
});

export const expandSwimlane = swimlaneId => ({
    type: 'EXPAND_SWIMLANE',
    payload: { swimlaneId }
});

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

export const ticketModalClosed = boardTicketId => ({
    type: 'TICKET_MODAL_CLOSED',
    payload: boardTicketId
});
