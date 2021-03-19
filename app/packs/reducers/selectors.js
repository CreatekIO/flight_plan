export const getOpenPRs = ({ pullRequests, repos }) => {
    let openPRs = {},
        count = 0;

    if (!Object.keys(pullRequests).length) {
        return { count, pullRequests: [] };
    }

    for (const pullRequestId in pullRequests) {
        const pullRequest = pullRequests[pullRequestId];
        const repo = repos[pullRequest.repo];

        if (repo && pullRequest.state === "open") {
            openPRs[repo.id] = openPRs[repo.id] || [];
            openPRs[repo.id].push(pullRequest);
            count++;
        }
    }

    let openPRsByRepo = [];

    for (const repoId in openPRs) {
        openPRsByRepo.push({ ...repos[repoId], pullRequests: openPRs[repoId] });
    }

    return {
        count: count,
        pullRequests: openPRsByRepo.sort(
            (a, b) => b.pullRequests.length - a.pullRequests.length
        )
    };
};
