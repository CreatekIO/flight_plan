import React from "react";
import { Provider } from "react-redux";

export const FakeStore = ({ state, children }) => {
    const store = {
        dispatch: console.log.bind(console, "dispatch"),
        getState: () => state,
        subscribe: () => () => {}
    };

    return <Provider store={store}>{children}</Provider>;
};

const urls = [
    { url: "https://github.com", title: "First title" },
    { url: "https://dev.createk.io", title: "Second title" },
];

export const nextActions = {
    singleGood: { type: "positive", urls: urls.slice(0, 1), text: "Good action" },
    singleBad: { type: "negative", urls: urls.slice(0, 1), text: "Bad action" },
    multiGood: { type: "positive", urls, text: "Good action" },
    multiBad: { type: "negative", urls, text: "Bad action" }
};

export const assignees = [
    "rjpaskin",
    "jcleary",
    "gmanningcr",
    "abigailbeadle",
    "tedmoyses"
].map(username => ({ username }));

export const makeTicket = ({
    repoName = "Test Repo",
    number = "123",
    state = "open",
    title,
    labelIds = [],
    pullRequestIds = [],
    ...others
}) => ({
    entities: {
        boardTickets: {
            1: {
                id: 1, ticket: 1,
                labels: labelIds, pull_requests: pullRequestIds, assignees: [],
                ...others
            }
        },
        tickets: {
            1: {
                id: 1,
                repo: 1,
                state,
                number,
                title,
                html_url: "https://github.com"
            }
        },
        repos: {
            1: { id: 1, name: repoName, slug: "createkio/test-repo" },
            2: { id: 2, name: "Another Repo", slug: "createkio/another-repo" }
        },
        labels: {
            1: { id: 1, name: "type: bug", colour: "f26754" },
            2: { id: 2, name: "enhancement", colour: "84b6eb" },
            3: { id: 3, name: "rework needed", colour: "7f74b6" },
            4: { id: 4, name: "type: security", colour: "efd700" },
            99: { id: 99, name: "very long label name for testing", colour: "ff0000" }
        },
        milestones: {
            1: { id: 1, title: "FlightPlan" },
            99: { id: 1, title: "Very long milestone name for testing" }
        },
        pullRequests: [
            { number: "123", state: "open" },
            { number: "999", state: "closed" },
            { number: "234", state: "closed", merged: true },
            { number: "123", state: "open", next_action: nextActions.singleGood },
            { number: "234", state: "open", next_action: nextActions.singleBad },
            { number: "123", state: "open", next_action: nextActions.multiGood },
            { number: "234", state: "open", next_action: nextActions.multiBad },
            { number: "555", state: "open", repo: 2, id: 555 },
            { number: "666", state: "closed", id: 666, next_action: nextActions.singleBad },
            { number: "777", state: "closed", merged: true, id: 777, next_action: nextActions.singleBad }
        ].reduce((acc, pr, index) => ({
            ...acc,
            [pr.id || index + 1]: {
                id: index + 1,
                repo: 1,
                title: `This is PR #${pr.number}`,
                html_url: "https://github.com",
                ...pr
            }
        }), {})
    }
});
