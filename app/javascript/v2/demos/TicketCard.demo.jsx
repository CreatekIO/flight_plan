import React from "react";
import { DragDropContext, Droppable } from "react-beautiful-dnd";

import { FakeStore, makeTicket, assignees } from "./store";
import TicketCard from "../components/TicketCard";

const Wrapped = ({ index, scenario, ...props }) => (
    <FakeStore state={makeTicket({ title: scenario, ...props })}>
        <div className="w-64 p-3 flex flex-col"> {/* mimic swimlane size + padding */}
            <TicketCard id={1} index={index} />

            <div className="mt-auto text-center text-sm text-gray-600">
                {scenario}
            </div>
        </div>
    </FakeStore>
);

let rowCount = 0;

const Row = ({ scenarios }) => (
    <Droppable droppableId={`demo-${rowCount++}`} isDropDisabled={true}>
        {({ innerRef, droppableProps, placeholder }) => (
            <div
                ref={innerRef}
                {...droppableProps}
                className="flex flex-row flex-wrap border-b border-gray-200 pt-6 pb-3"
            >
                {Object.keys(scenarios).map((name, index) => (
                    <Wrapped key={name} index={index} scenario={name} {...scenarios[name]} />
                ))}
                {placeholder}
            </div>
        )}
    </Droppable>
);

const Demo = () => (
    <DragDropContext onDragEnd={() => {}}>
        <Row scenarios={{
            "Basic": { title: "Demo ticket title" },
            "Long title": {
                title: `This is a very long ticket title that is testing very long titles
                        just to see how long a ticket title can get`
            },
            "Long repo name": {
                repoName: "This is a very long repo name that is very long"
            }
        }} />
        <Row scenarios={{
            ...[1, 2, 3, 4, 5].reduce((scenarios, count) => ({
                ...scenarios,
                [`With ${count} assignee${ count === 1 ? "" : "s"}`]: { assignees: assignees.slice(0, count) }
            }), {}),
            "With long repo name": { assignees, repoName: "This is a very long repo name" }
        }} />
        <Row scenarios={{
            "With 1 label, no milestone": { labels: [1] },
            "With 2 labels, no milestone": { labels: [1, 2] },
            "With 3 labels, no milestone": { labels: [1, 2, 3] },
            "With 4 labels, no milestone": { labels: [1, 2, 3, 4] },
            "With long label, no milestone": { labels: [99] },
            "With long label and long milestone": { labels: [99], milestone: 99 }
        }} />
        <Row scenarios={{
            "With milestone, no labels": { milestone: 1 },
            "With milestone and 1 label": { labels: [1], milestone: 1 },
            "With milestone and 2 labels": { labels: [1, 2], milestone: 1 },
            "With milestone and 3 labels": { labels: [1, 2, 3], milestone: 1 },
            "With milestone and 4 labels": { labels: [1, 2, 3, 4], milestone: 1 },
            "With long milestone, no labels": { milestone: 99 },
            "With long milestone and 1 label": { milestone: 99, labels: [1] }
        }} />
        <Row scenarios={{
            "With duration": { shouldDisplayDuration: true, time_since_last_transition: "< 1h" },
            "With duration and label": { shouldDisplayDuration: true, time_since_last_transition: "< 1h", labels: [1] },
            "With duration and milestone": { shouldDisplayDuration: true, time_since_last_transition: "< 1h", milestone: 1 },
            "With duration and PR": { shouldDisplayDuration: true, time_since_last_transition: "< 1h", pullRequestIds: [1] }
        }} />
        <Row scenarios={{
            "With 1 PR": { pullRequestIds: [1] },
            "With 2 PRs": { pullRequestIds: [1, 2] },
            "With 3 PRs": { pullRequestIds: [1, 2, 3] },
            "With 1 PR w/ action": { pullRequestIds: [4] },
            "With 2 PRs w/ action": { pullRequestIds: [4, 5] },
            "With 1 PR w/ multi action": { pullRequestIds: [6] },
            "With 2 PRs w/ multi action": { pullRequestIds: [6, 7] },
            "With 1 closed PR w/ action": { pullRequestIds: [666] },
            "With 1 merged PR w/ action": { pullRequestIds: [777] }
        }} />
    </DragDropContext>
);

export default Demo;
