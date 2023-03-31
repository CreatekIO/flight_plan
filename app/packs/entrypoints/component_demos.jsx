import { createRoot } from "react-dom/client";

import Root from "../demos";

const rootRender = () =>
    createRoot(document.querySelector("#root")).render(<Root />);

document.addEventListener("DOMContentLoaded", rootRender);
