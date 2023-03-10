import ReactDOM from "react-dom";

import Application from "../components/Application";

const rootRender = () => {
    ReactDOM.render(
        <Application />,
        document.querySelector("#react_board")
    );
};

document.addEventListener("DOMContentLoaded", rootRender);
