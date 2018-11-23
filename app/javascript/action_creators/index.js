export const loadBoard = url => dispatch =>
    fetch(url)
        .then(response => response.json())
        .then(board => dispatch(boardLoaded(board)));

export const boardLoaded = board => ({
    type: "BOARD_LOAD",
    payload: board
});
