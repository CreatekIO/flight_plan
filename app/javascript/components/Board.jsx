import React, { Component } from "react";

import Swimlane from "./Swimlane";

export default class Board extends Component {
    state = { isLoading: true, swimlanes: [] };

    componentDidMount() {
        $.getJSON(flightPlanConfig.api.boardURL).then(swimlanes => {
            this.setState({
                isLoading: false,
                swimlanes: swimlanes
            });
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
