import { getBoard, getBoardNextActions, getSwimlaneTickets } from "../api";

const extractId = identifier => identifier.split("-")[1];

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

export const ticketDragged = ({ source, destination }) => ({
    type: "TICKET_MOVED",
    payload: {
        sourceId: extractId(source.droppableId),
        sourceIndex: source.index,
        destinationId: extractId(destination.droppableId),
        destinationIndex: destination.index
    }
});

export const boardLoaded = board => ({
    type: "BOARD_LOAD",
    payload: board
});

export const nextActionsLoaded = repos => ({
    type: "NEXT_ACTIONS_LOADED",
    payload: repos
});

export const swimlaneTicketsLoading = swimlaneId => ({
    type: "SWIMLANE_TICKETS_LOADING",
    payload: { swimlaneId }
});

export const swimlaneTicketsLoaded = swimlane => ({
    type: "SWIMLANE_TICKETS_LOADED",
    payload: swimlane
});
