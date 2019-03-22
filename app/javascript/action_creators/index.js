import { getBoard, getBoardNextActions } from "../api";

export const loadBoard = () => dispatch =>
    getBoard().then(board => dispatch(boardLoaded(board)));

export const loadNextActions = () => dispatch =>
    getBoardNextActions().then(repos => dispatch(nextActionsLoaded(repos)));

export const boardLoaded = board => ({
    type: "BOARD_LOAD",
    payload: board
});

export const nextActionsLoaded = repos => ({
    type: "NEXT_ACTIONS_LOADED",
    payload: repos
});
