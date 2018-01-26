import React, { Component } from "react";
import axios from "axios";
import Header from "./Header";

class Boards extends Component {
  state = {
    apiData: { boards: [] }
  };
  componentDidMount() {
    axios
      .get("http://dev.createk.io/api/boards.json")
      .then((response: { data: string }) => {
        console.log(response.data);
        this.setState({ apiData: { boards: response.data } });
      });
  }

  render() {
    let boardComponent;
    if (this.state.apiData.boards) {
      return <Header boards={this.state.apiData.boards} />;
    } else {
      return <Header boards="No boards" />;
    }
  }
}

export default Boards;
