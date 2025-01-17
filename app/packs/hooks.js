import { useEffect } from "react";
import { useMatch, useLocation } from "@gatsbyjs/reach-router";
import { useDispatch, useSelector } from "react-redux";
import { createConsumer } from "@rails/actioncable";
import useScrollbarSize from "react-scrollbar-size";

import { isFeatureDisabled } from "./features";

// You can't use regexes with Reach Router, so this hook provides
// a way to set additional constraints on path params, like Rails
export const useConstrainedMatch = (path, constraints) => {
    const match = useMatch(path);
    if (!match) return null;

    for (const [key, constraint] of Object.entries(constraints)) {
        const param = match[key];

        if (Array.isArray(constraint) && !constraint.includes(param)) return null;
        if (constraint instanceof RegExp && !constraint.test(param)) return null;
        if ({}.toString.call(constraint) === "function" && !constraint(param, key, match)) return null;
        if (typeof constraints === "string" && constraint !== param) return null;
    }

    return match;
};

let cable;

export const useSubscription = (channel, id) => {
    const dispatch = useDispatch();

    useEffect(() => {
        if (isFeatureDisabled("realtime_updates")) return () => {};

        cable = cable || createConsumer();

        const subscription = cable.subscriptions.create(
            { channel, id: parseInt(id, 10) },
            { received: dispatch }
        );

        return () => {
            try {
                subscription.unsubscribe();
            } catch(_) {}
        };
    }, [channel, id])
};

const EMPTY_STATE = Object.freeze({});

export const useLocationState = () => {
    const { state } = useLocation();

    return state || EMPTY_STATE;
};

export const useEntity = (rawType, id) => {
    const type = rawType.endsWith("s") ? rawType : `${rawType}s`;

    return useSelector(({ entities }) => entities[type][id]);
};

export const useScrollbarHeight = () => {
    const { height } = useScrollbarSize();
    const dispatch = useDispatch();

    useEffect(() => {
        dispatch({ type: "ui/scrollbarHeightChanged", payload: { height }});
    }, [height]);
};
