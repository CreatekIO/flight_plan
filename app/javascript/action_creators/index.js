import { getBoard, getBoardNextActions } from "../api";

const extractId = identifier => identifier.split("-")[1];

export const loadBoard = () => dispatch =>
    getBoard().then(board => dispatch(boardLoaded(board)));

export const loadNextActions = () => dispatch =>
    getBoardNextActions().then(repos => dispatch(nextActionsLoaded(repos)));

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
