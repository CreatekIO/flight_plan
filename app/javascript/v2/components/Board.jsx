import React, { Component } from "react";
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

class Board extends Component {
    state = { isLoading: true };

    componentDidMount() {
        const { loadBoard, loadNextActions, subscribeToBoard } = this.props;

        loadBoard()
            .then(({ payload: { id } }) => {
                this.boardSubscription = subscribeToBoard(id);
            })
            .finally(() => this.setState({ isLoading: false }));
        loadNextActions();
    }

    componentWillUnmount() {
        this.boardSubscription && this.boardSubscription.unsubscribe();
    }

    onDragEnd = event => {
        if (!event.destination) return;

        this.props.ticketDragged(event);
    };

    render() {
        return (
            <DragDropContext onDragEnd={this.onDragEnd}>
                <main className="fp-board flex flex-1 flex-nowrap mt-12 relative">
                    {this.props.swimlanes.map(swimlaneId => (
                        <Swimlane key={swimlaneId} id={swimlaneId} />
                    ))}
                    {this.state.isLoading && <LoadingOverlay/>}
                </main>
            </DragDropContext>
        );
    }
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
