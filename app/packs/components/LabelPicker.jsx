import { useEffect, useCallback } from "react";
import { connect } from "react-redux";
import { useNavigate } from "@reach/router";
import classNames from "classnames";
import { toast } from "react-toastify";

import Picker from "./Picker";
import { fetchLabelsForRepo } from "../slices/labels";
import { updateLabelsForTicket } from "../slices/board_tickets";

const ColourIcon = ({ isSelected, item: { colour }}) => (
    <span
        className={classNames(
            "rounded-full w-4 h-4 inline-block bg-gray-100 mr-2",
            { "ml-5": !isSelected }
        )}
        style={{ backgroundColor: `#${colour}` }}
    />
);

const LabelPicker = ({
    boardTicketId,
    currentLabelIds,
    repoLabels,
    repoId,
    backPath,
    enableAfter,
    fetchLabelsForRepo,
    updateLabelsForTicket
}) => {
    useEffect(() => { fetchLabelsForRepo(repoId) }, [repoId]);

    const navigate = useNavigate();

    const onSubmit = useCallback(selectedIds => {
        updateLabelsForTicket({
            id: boardTicketId,
            add: selectedIds.filter(id => !currentLabelIds.includes(id)),
            remove: currentLabelIds.filter(id => !selectedIds.includes(id))
        }).then(({ meta, payload, error }) => {
            if (error && !meta.condition) {
                if (meta.rejectedWithValue) {
                    payload.forEach(message => toast.error(message));
                } else {
                    toast.error("Failed to update labels");
                }
            } else {
                toast.success("Labels updated");
            }
        });

        navigate(`../${backPath}`);
    }, [boardTicketId, currentLabelIds, backPath]);

    return (
        <Picker
            label="Edit labels"
            placeholder="Filter labels"
            availableItems={repoLabels}
            currentIds={currentLabelIds}
            backPath={backPath}
            nameProp="name"
            icon={ColourIcon}
            onSubmit={onSubmit}
            enableAfter={enableAfter}
        />
    )
};

const EMPTY = [];

const mapStateToProps = (_, { boardTicketId }) => ({
    entities: { boardTickets, labels, tickets }
}) => {
    const boardTicket = boardTickets[boardTicketId];
    const ticket = boardTicket && tickets[boardTicket.ticket];

    const currentLabelIds = boardTicket ? boardTicket.labels : EMPTY;

    const repoId = ticket && ticket.repo;
    const repoLabels = repoId
        ? Object.values(labels).filter(({ repo }) => repo === repoId)
        : EMPTY;

    repoLabels.sort((a, b) => {
        const aIsActive = currentLabelIds.includes(a.id);
        const bIsActive = currentLabelIds.includes(b.id);

        if (aIsActive != bIsActive) {
            // put the active item first - if we get here it's guaranteed
            // that if `a` is active, `b` is not, and vice-versa
            return aIsActive ? -1 : 1;
        } else {
            // both are either active or inactive, so sort by name
            // - should be case-insensitive by default
            return a.name.localeCompare(b.name);
        }
    });

    return { currentLabelIds, repoLabels, repoId };
};

export default connect(
    mapStateToProps,
    { fetchLabelsForRepo, updateLabelsForTicket }
)(LabelPicker);
