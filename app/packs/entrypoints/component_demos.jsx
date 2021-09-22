import "core-js/stable";
import "regenerator-runtime/runtime";
import React from "react";
import ReactDOM from "react-dom";

const rootRender = () => {
    const Root = require("../demos").default;

    ReactDOM.render(
        <Root />,
        document.querySelector("#root")
    );
};

document.addEventListener("DOMContentLoaded", rootRender);

if (module.hot) {
    module.hot.accept("../demos", rootRender);
}
