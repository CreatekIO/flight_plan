import { Children, cloneElement, useState } from "react";
import {
    useFloating,
    autoUpdate,
    offset,
    flip,
    shift,
    useHover,
    useFocus,
    useDismiss,
    useRole,
    useInteractions,
    FloatingPortal
} from "@floating-ui/react";

// Based on example from Floating UI docs
// https://codesandbox.io/s/xenodochial-grass-js3bo9?file=/src/Tooltip.tsx
const Tooltip = ({ label, placement = "bottom", children }) => {
    const [open, setOpen] = useState(false);

    const { x, y, refs, strategy, context } = useFloating({
        open: open,
        onOpenChange: setOpen,
        placement,
        // Ensure tooltip stays on the screen
        whileElementsMounted: autoUpdate,
        middleware: [
            offset(5),
            flip({ fallbackAxisSideDirection: "start", crossAxis: false }),
            shift()
        ]
    });

    const { getReferenceProps, getFloatingProps } = useInteractions([
        useHover(context, { move: false }),
        useFocus(context),
        useDismiss(context),
        useRole(context, { role: "tooltip" })
    ]);

    const child = Children.only(children);

    return (
        <>
            {cloneElement(child, getReferenceProps({ ref: refs.setReference }))}

            {open && (
                <FloatingPortal>
                    <div
                        className="absolute bg-black border-black text-white rounded shadow-xl text-xs w-max px-2 py-1 z-50"
                        style={{
                            position: strategy,
                            top: y || 0,
                            left: x || 0
                        }}
                        {...getFloatingProps({ ref: refs.setFloating })}
                    >
                        {label}
                    </div>
                </FloatingPortal>
            )}
        </>
    );
};

export default Tooltip;
