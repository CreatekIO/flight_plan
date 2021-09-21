import React from "react";
import { DialogOverlay, DialogContent } from "@reach/dialog";

const Modal = ({ children, "aria-labelledby": labelId, ...props }) => (
    <DialogOverlay {...props} className="bg-black bg-opacity-80 z-40">
        <DialogContent
            className="shadow-2xl rounded max-w-5xl w-full p-0 overflow-hidden relative"
            style={{ margin: "10vh auto", height: "80vh" }}
            aria-labelledby={labelId}
        >
            {children}
        </DialogContent>
    </DialogOverlay>
);

export default Modal;