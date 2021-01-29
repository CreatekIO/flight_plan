import { useMatch } from "@reach/router";

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
