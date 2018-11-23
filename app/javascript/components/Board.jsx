import React, { Component } from "react";
import { connect } from "react-redux";

import Swimlane from "./Swimlane";

import { loadBoard } from "../action_creators";

class Board extends Component {
    state = { isLoading: true };

    componentDidMount() {
        this.props.loadBoard().then(() => this.setState({ isLoading: false }));
    }

    renderOverlay() {
        return (
            <div className="ui active inverted dimmer">
                <div className="ui text large loader">Loading</div>
            </div>
        );
    }

    render() {
        return (
            <div className="board">
                {this.props.swimlanes.map(swimlaneId => (
                    <Swimlane key={swimlaneId} id={swimlaneId} />
                ))}
                {this.state.isLoading && this.renderOverlay()}
            </div>
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

export default connect(mapStateToProps, { loadBoard })(Board);
