import {
    useFloating,
    autoUpdate,
    useClick,
    useDismiss,
    useRole,
    useInteractions,
    FloatingPortal,
    FloatingOverlay,
    FloatingFocusManager
} from "@floating-ui/react";

// Based on example from Floating UI docs
// https://codesandbox.io/s/stoic-bas-frzus0?file=/src/App.tsx
const Modal = ({ children, "aria-labelledby": labelId, onDismiss }) => {
    const { refs, context } = useFloating({
        open: true,
        onOpenChange: onDismiss
    });

    const { getReferenceProps, getFloatingProps } = useInteractions([
        useClick(context),
        useRole(context),
        useDismiss(context)
    ]);

    return (
        <FloatingPortal>
            <FloatingOverlay className="bg-black/80 z-40">
                <FloatingFocusManager context={context} lockScroll>
                    <div
                        className="bg-white shadow-2xl rounded max-w-5xl w-full p-0 overflow-hidden relative m-[10vh_auto] h-[80vh]"
                        aria-labelledby={labelId}
                        {...getFloatingProps({ ref: refs.setFloating })}
                    >
                        {children}
                    </div>
                </FloatingFocusManager>
            </FloatingOverlay>
        </FloatingPortal>
    );
};

export default Modal;
