import { FloatingPortal } from "@floating-ui/react";
import { ToastContainer, cssTransition, toast } from "react-toastify";
import classNames from "classnames";
import { XIcon } from "@primer/octicons-react";

const { INFO, WARNING, ERROR, SUCCESS } = toast.TYPE;

const CLASSES = {
    [INFO]: "bg-blue-200 border-blue-500 text-blue-800",
    [WARNING]: "bg-yellow-200 border-yellow-500 text-yellow-800",
    [ERROR]: "bg-red-200 border-red-500 text-red-800",
    [SUCCESS]: "bg-green-200 border-green-500 text-green-800"
};

const generateToastClassName = ({ type }) => classNames(
    "relative p-4 w-64 shadow-xl mb-2 border-l-4 text-sm",
    CLASSES[type] || CLASSES[INFO]
);

const Transition = cssTransition({
    enter: "animate-toast-in",
    exit: "animate-toast-out",
    collapseDuration: 150
});

const CloseButton = ({ closeToast }) => (
    <button
        className="absolute top-1 right-2 opacity-50 hover:opacity-100 focus:opacity-100"
        aria-label="Close"
        onClick={closeToast}
    >
        <XIcon />
    </button>
);

const Notifications = () => (
    <FloatingPortal>
        <ToastContainer
            autoClose={5000}
            className="fixed top-4 right-4 z-50"
            closeButton={CloseButton}
            draggable={false}
            hideProgressBar={true}
            icon={false}
            newestOnTop={false}
            pauseOnFocusLoss={true}
            pauseOnHover={true}
            role="status"
            toastClassName={generateToastClassName}
            transition={Transition}
        />
    </FloatingPortal>
);


export default Notifications;
