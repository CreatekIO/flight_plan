import React from "react";

// import Header from './Header'
import Board from "./Board";

const Application = props => {
    // const board = { name: 'Other Board', other_name: 'Other 12' }
    const { swimlanes } = props;

    return (
        // <Header board={board}/>
        <Board />
    );
};

export default Application;
