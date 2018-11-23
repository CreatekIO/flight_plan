import { getBoard } from "../api";

export const loadBoard = () => dispatch =>
    getBoard().then(board => dispatch(boardLoaded(board)));

export const boardLoaded = board => ({
    type: "BOARD_LOAD",
    payload: board
});
