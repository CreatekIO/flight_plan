import { createRoot } from "react-dom/client";

import Application from "../components/Application";

const rootRender = () =>
    createRoot(document.querySelector("#react_board")).render(<Application />);

document.addEventListener("DOMContentLoaded", rootRender);
