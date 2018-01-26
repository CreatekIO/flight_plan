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
    if (this.state.apiData.boards.length >= 1) {
      return <Header boards={this.state.apiData.boards} />;
    } else {
      return <Header boards={[{ name: "no boards" }]} />;
    }
  }
}

export default Boards;
