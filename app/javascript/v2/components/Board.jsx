import React, { useState, useEffect, useCallback } from "react";
import { connect } from "react-redux";
import { DragDropContext } from "react-beautiful-dnd";
import update from "immutability-helper";

import Swimlane from "./Swimlane";
import Loading from "./Loading";

import {
    loadBoard,
    loadNextActions,
    ticketDragged,
    subscribeToBoard
} from "../../action_creators";

const LoadingOverlay = () => (
    <div className="absolute inset-0 bg-white bg-opacity-50 flex flex-col items-center justify-center text-gray-600">
        <Loading size="large" />
        <p className="animate-pulse text-lg mt-3">Loading...</p>
    </div>
);

const Board = ({
    swimlanes,
    loadBoard,
    loadNextActions,
    ticketDragged,
    subscribeToBoard
}) => {
    const [isLoading, setLoading] = useState(true);

    useEffect(() => {
        let boardSubscription;

        loadBoard()
            .then(({ payload: { id } }) => { boardSubscription = subscribeToBoard(id) })
            .finally(() => setLoading(false));
        loadNextActions();

        return () => boardSubscription && boardSubscription.unsubscribe();
    }, [loadBoard, loadNextActions]);

    const onDragEnd = useCallback(
        event => event.destination && ticketDragged(event),
        [ticketDragged]
    );

    return (
        <DragDropContext onDragEnd={onDragEnd}>
            <main className="fp-board flex flex-1 flex-nowrap mt-14 relative">
                {swimlanes.map(swimlaneId => (
                    <Swimlane key={swimlaneId} id={swimlaneId} />
                ))}
                {isLoading && <LoadingOverlay/>}
            </main>
        </DragDropContext>
    );
}

const mapStateToProps = ({ entities, current }) => {
    let swimlanes = [];

    if (current.board) {
        swimlanes = entities.boards[current.board].swimlanes;
    }

    return {
        swimlanes
    };
};

export default connect(
    mapStateToProps,
    { loadBoard, loadNextActions, ticketDragged, subscribeToBoard }
)(Board);
