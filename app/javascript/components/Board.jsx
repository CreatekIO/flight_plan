import React, { Component } from "react";
import { connect } from "react-redux";
import { DragDropContext } from "react-beautiful-dnd";
import update from "immutability-helper";

import Swimlane from "./Swimlane";

import {
    loadBoard,
    loadNextActions,
    ticketDragged,
    subscribeToBoard
} from "../action_creators";

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

    renderOverlay() {
        return (
            <div className="ui active inverted dimmer">
                <div className="ui text large loader">Loading</div>
            </div>
        );
    }

    render() {
        return (
            <DragDropContext onDragEnd={this.onDragEnd}>
                <div className="board">
                    {this.props.swimlanes.map(swimlaneId => (
                        <Swimlane key={swimlaneId} id={swimlaneId} />
                    ))}
                    {this.state.isLoading && this.renderOverlay()}
                </div>
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
