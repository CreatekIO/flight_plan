import React, { useState, useEffect, useCallback } from "react";
import { connect } from "react-redux";
import { DragDropContext } from "react-beautiful-dnd";
import update from "immutability-helper";

import Swimlane from "./Swimlane";
import Loading from "./Loading";
import { fetchBoard } from "../slices/boards";
import { fetchNextActions } from "../slices/pull_requests";

import { ticketDragged, subscribeToBoard } from "../../action_creators";

const LoadingOverlay = () => (
    <div className="absolute inset-0 bg-white bg-opacity-50 flex flex-col items-center justify-center text-gray-600">
        <Loading size="large" />
        <p className="animate-pulse text-lg mt-3">Loading...</p>
    </div>
);

const Board = ({
    boardId,
    swimlaneIds,
    fetchBoard,
    fetchNextActions,
    ticketDragged,
    subscribeToBoard
}) => {
    const [isLoading, setLoading] = useState(true);

    useEffect(() => {
        let boardSubscription;

        fetchBoard()
            .then(() => { boardSubscription = subscribeToBoard(boardId) })
            .finally(() => setLoading(false));
        fetchNextActions(boardId);

        return () => boardSubscription && boardSubscription.unsubscribe();
    }, [fetchBoard, fetchNextActions]);

    const onDragEnd = useCallback(
        event => event.destination && ticketDragged(event),
        [ticketDragged]
    );

    return (
        <DragDropContext onDragEnd={onDragEnd}>
            <main className="fp-board flex flex-1 flex-nowrap mt-14 relative">
                {swimlaneIds.map(id => <Swimlane key={id} id={id} />)}

                {isLoading && <LoadingOverlay/>}
            </main>
        </DragDropContext>
    );
}

const EMPTY = [];

const mapStateToProps = (_, { boardId: id }) => ({
    entities: { boards }
}) => ({
    swimlaneIds: (boards[id] && boards[id].swimlanes) || EMPTY
})

export default connect(
    mapStateToProps,
    { fetchBoard, fetchNextActions, ticketDragged, subscribeToBoard }
)(Board);
