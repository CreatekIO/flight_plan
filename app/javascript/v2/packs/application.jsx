import "core-js/stable";
import "regenerator-runtime/runtime";
import React from "react";
import ReactDOM from "react-dom";

const rootRender = () => {
    const Application = require("../components/Application").default;

    ReactDOM.render(
        <Application />,
        document.querySelector("#react_board")
    );
};

const preserveScrollPosition = (selector, fn) => {
    let element = document.querySelector(selector);
    const scrollLeft = (element && element.scrollLeft) || 0;

    fn();

    element = document.querySelector(selector);
    if (element) element.scrollLeft = scrollLeft;
}

document.addEventListener("DOMContentLoaded", rootRender);

if (module.hot) {
    module.hot.accept("../components/Application", () => {
        preserveScrollPosition(".fp-board", rootRender);
    });
}
