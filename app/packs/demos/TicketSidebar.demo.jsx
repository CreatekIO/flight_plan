import { FakeStore, makeTicket, assignees } from "./store";
import TicketSidebar from "../components/TicketSidebar";

const Scenario = ({ name, ...props }) => (
    <div className="mr-4 flex flex-col">
        <div className="border border-dashed border-gray-200 p-2 mb-4">
            <FakeStore state={makeTicket(props)}>
                <TicketSidebar id={1} className="w-64 mb-8" />
            </FakeStore>
        </div>

        <div className="text-center text-sm text-gray-600 mt-auto">
            {name}
        </div>
    </div>
);

const Divider = () => <hr className="w-full my-8" />;

const Demo = () => (
    <div className="flex flex-wrap py-2">
        <Scenario name="Blank slate" />
        <Scenario name="Closed" state="closed" />
        <Scenario name="With milestone" milestone={1} />
        <Scenario name="With long milestone" milestone={99} />

        <Divider />

        {[1, 2, 3].map(num => (
            <Scenario
                key={num}
                name={`With ${num} label${num === 1 ? "" : "s"}`}
                labelIds={[1, 2, 3].slice(0, num)}
            />
        ))}

        <Scenario name="With long label" labelIds={[99]} />

        <Divider />

        {[1, 2, 3].map(num => (
            <Scenario
                key={num}
                name={`With ${num} assignee${num === 1 ? "" : "s"}`}
                assignees={assignees.slice(0, num)}
            />
        ))}

        <Divider />

        <Scenario name="With 1 PR" pullRequestIds={[1]} />
        <Scenario name="With 2 PRs" pullRequestIds={[1, 2]} />
        <Scenario name="With 3 PRs" pullRequestIds={[1, 2, 3]} />
        <Scenario name="With 2 PRs w/ actions" pullRequestIds={[4, 5]} />

        <Divider />

        <Scenario name="With 2 PRs from 2 repos" pullRequestIds={[1, 555]} />
        <Scenario name="With 3 PRs from 2 repos" pullRequestIds={[1, 2, 555]} />
        <Scenario name="With 3 PRs w/ actions from 2 repos" pullRequestIds={[4, 5, 555]} />
    </div>
);

export default Demo;
