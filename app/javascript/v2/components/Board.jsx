import React, { useState, useEffect, useCallback } from "react";
import { connect } from "react-redux";
import { DragDropContext } from "react-beautiful-dnd";
import update from "immutability-helper";

import Swimlane from "./Swimlane";
import Loading from "./Loading";
import { fetchBoard } from "../slices/boards";
import { moveTicket } from "../slices/board_tickets";
import { fetchNextActions } from "../slices/pull_requests";

import { subscribeToBoard } from "../../action_creators";

// Format is `Component/model_name#id`
const extractId = id => parseInt(id.split("#")[1], 10);

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
    moveTicket,
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
        ({ draggableId, source, destination }) => {
            if (!destination) return;

            moveTicket({
                boardTicketId: extractId(draggableId),
                from: {
                    swimlaneId: extractId(source.droppableId),
                    index: source.index,
                },
                to: {
                    swimlaneId: extractId(destination.droppableId),
                    index: destination.index
                }
            });
        },
        [moveTicket]
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
    { fetchBoard, fetchNextActions, moveTicket, subscribeToBoard }
)(Board);
