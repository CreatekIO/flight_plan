import React from "react";

// import Header from './Header'
import Swimlane from "./Swimlane";

const Application = props => {
    // const board = { name: 'Other Board', other_name: 'Other 12' }
    const { swimlanes } = props;

    return (
        // <Header board={board}/>
        <div className="board">
            {swimlanes.map(swimlane => <Swimlane {...swimlane} key={swimlane.id} />)}
        </div>
    );
};

export default Application;
