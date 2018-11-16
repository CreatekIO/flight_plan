import React, { Component } from "react";
import { connect } from "react-redux";

import Swimlane from "./Swimlane";

import { boardLoaded } from "../action_creators";

class Board extends Component {
    state = { isLoading: true };

    componentDidMount() {
        fetch(flightPlanConfig.api.boardURL)
            .then(response => response.json())
            .then(board => {
                this.setState({
                    isLoading: false
                });

                this.props.boardLoaded(board);
            });
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
                {this.state.swimlanes.map(swimlane => (
                    <Swimlane {...swimlane} key={swimlane.id} />
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

export default connect(mapStateToProps, { boardLoaded })(Board);
