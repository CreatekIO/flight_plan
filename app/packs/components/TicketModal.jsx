import { Fragment, useState, useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { navigate, Link } from "@gatsbyjs/reach-router";
import classNames from "classnames";

import { useConstrainedMatch, useLocationState } from "../hooks";
import Modal from "./Modal";
import Loading from "./Loading";
import Sidebar from "./TicketSidebar";
import Feed from "./TicketFeed";
import FormWrapper from "./TicketFormWrapper";
import AssigneePicker from "./AssigneePicker";
import LabelPicker from "./LabelPicker";
import { fetchTicket } from "../slices/board_tickets";

const transitionClasses = "transition-transform duration-150";
const TRANSITION_DURATION = 150; // should match `duration-*` class above

const EDITORS = {
    labels: LabelPicker,
    assignees: AssigneePicker,
    milestone: () => (<FormWrapper label="Edit milestone" backPath="." />)
};

const useTrailingState = current => {
    const [previous, setPrevious] = useState(null);

    useEffect(() => { current && setPrevious(current) }, [current]);

    const reset = () => {
        if (!current) setPrevious(null);
    }

    return [current || previous, reset];
};

const TicketModal = ({
    owner,
    repo,
    number
}) => {
    const slug = `${owner}/${repo}`;
    const labelId = `ticket-modal-${owner}-${repo}-${number}`;

    const { boardTicketId } = useLocationState();
    const [id, setId] = useState(boardTicketId);
    const [isLoaded, setIsLoaded] = useState(false);
    const dispatch = useDispatch();

    const { section } = useConstrainedMatch(
        ":section/edit",
        { section: ["labels", "assignees", "milestone"] }
    ) || {};

    const [activeSection, resetActiveSection] = useTrailingState(section);
    const ActiveEditor = activeSection && EDITORS[activeSection];

    const title = useSelector(
        ({ entities: { boardTickets, tickets }}) => {
            const boardTicket = id && boardTickets[id];
            if (!boardTicket) return;

            const ticket = tickets[boardTicket.ticket];
            return ticket && ticket.title;
        }
    );

    useEffect(() => {
        dispatch(fetchTicket({ slug, number }))
            .then(({ meta: { requestStatus }, payload: { boardTicketId }}) => {
                if (requestStatus === "fulfilled") setId(boardTicketId);
            })
            .finally(() => setIsLoaded(true))
    }, [slug, number]);

    return (
        <Modal
            onDismiss={() => navigate(flightPlanConfig.api.htmlBoardURL)}
            aria-labelledby={labelId}
        >
            <div
                className="text-lg border-b border-gray-300 p-4 pb-3 font-bold bg-white"
                id={labelId}
            >
                <a
                    href={`https://github.com/${slug}/issues/${number}`}
                    target="_blank"
                    className="text-blue-500 hover:text-blue-600"
                >
                    #{number}
                </a>
                &nbsp;&nbsp;
                {title}
            </div>

            <div className="absolute top-14 inset-0 overflow-auto mt-px">
                {isLoaded && (
                    <div className="sticky w-56 top-4 right-0 ml-auto overflow-x-hidden">
                        <Sidebar
                            id={id}
                            className={classNames(
                                "pr-3 pb-12",
                                transitionClasses,
                                section ? "-translate-x-56" : "translate-x-0"
                            )}
                        />
                    </div>
                )}

                {/* Put <Feed/> after <Sidebar/> in the DOM so that it has a higher z-index */}
                {/* sidebar width (w-56) + gutter (pl-5) */}
                <div className="absolute left-4 top-4 pr-5 bg-white w-[calc(100%-(theme(spacing.56)+theme(spacing.5)))]">
                    <Feed id={id} />

                    {!isLoaded && (
                        <div className="flex justify-center text-gray-600 absolute inset-0 bg-white/50">
                            <Loading size="large" className="mt-14"/>
                        </div>
                    )}
                </div>
            </div>

            {isLoaded && (
                <div
                    className={classNames(
                        "w-56 absolute top-14 bottom-0 right-0 pt-4 mt-px border-l border-gray-300 bg-gray-100",
                        transitionClasses,
                        section ? "translate-x-0" : "translate-x-56"
                    )}
                    /* Ensure we keep the editor in the DOM until the transition ends */
                    onTransitionEnd={resetActiveSection}
                >
                    {/* As soon as we navigate to a section, mount the corresponding editor */}
                    {/* so that it's present before the transition starts */}
                    {Boolean(ActiveEditor) && (
                        <ActiveEditor boardTicketId={id} backPath="." enableAfter={TRANSITION_DURATION} />
                    )}
                </div>
            )}
        </Modal>
    );
}

export default TicketModal;
