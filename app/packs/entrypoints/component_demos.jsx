import ReactDOM from "react-dom";

import Root from "../demos";

const rootRender = () => {
    ReactDOM.render(
        <Root />,
        document.querySelector("#root")
    );
};

document.addEventListener("DOMContentLoaded", rootRender);

if (module.hot) {
    module.hot.accept("../demos", rootRender);
}
