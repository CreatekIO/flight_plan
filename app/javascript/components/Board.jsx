import React, { Component } from "react";
import { connect } from "react-redux";
import { DragDropContext } from "react-beautiful-dnd";

import Swimlane from "./Swimlane";

import { loadBoard, loadNextActions } from "../action_creators";

class Board extends Component {
    state = { isLoading: true };

    componentDidMount() {
        this.props.loadBoard().then(() => this.setState({ isLoading: false }));
        this.props.loadNextActions();
    }

    onDragEnd = (result, provided) => {
        console.log(result, provided);
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
    { loadBoard, loadNextActions }
)(Board);
