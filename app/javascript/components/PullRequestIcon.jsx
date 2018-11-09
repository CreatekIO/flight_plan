import React from "react";
import Octicon, { GitMerge, GitPullRequest } from "@githubprimer/octicons-react";

export default function PullRequestIcon({ merged, state }) {
    if (merged) {
        return <Octicon icon={GitMerge} className="octicon is-merged" />;
    } else {
        return <Octicon icon={GitPullRequest} className={`octicon is-${state}`} />;
    }
}
