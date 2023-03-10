import { useEffect, useCallback } from "react";
import { connect } from "react-redux";
import { useNavigate } from "@reach/router";
import classNames from "classnames";
import { toast } from "react-toastify";

import Avatar from "./Avatar";
import Picker from "./Picker";
import { fetchAssigneesForRepo } from "../slices/repos";
import { updateAssigneesForTicket } from "../slices/board_tickets";

const AssigneeAvatar = ({ isSelected, item: { username }}) => (
    <Avatar
        username={username}
        size="mini"
        className={classNames("mr-2", { "ml-5": !isSelected })}
    />
);

const AssigneePicker = ({
    boardTicketId,
    currentAssigneeIds,
    repoAssignees,
    repoId,
    backPath,
    enableAfter,
    fetchAssigneesForRepo,
    updateAssigneesForTicket
}) => {
    useEffect(() => { fetchAssigneesForRepo(repoId) }, [repoId]);

    const navigate = useNavigate();

    const onSubmit = useCallback(selectedIds => {
        const add = selectedIds
            .filter(id => !currentAssigneeIds.includes(id))
            .map(id => repoAssignees.find(({ id: assigneeId }) => assigneeId === id))
            .filter(Boolean)
            .map(({ id, username }) => ({ remote_id: id, username }));

        const remove = currentAssigneeIds
            .filter(id => !selectedIds.includes(id))
            .map(id => repoAssignees.find(({ id: assigneeId }) => assigneeId === id))
            .filter(Boolean)
            .map(({ id, username }) => ({ remote_id: id, username }));

        updateAssigneesForTicket({
            id: boardTicketId,
            add,
            remove
        }).then(({ meta, payload, error }) => {
            if (error && !meta.condition) {
                if (meta.rejectedWithValue) {
                    payload.forEach(message => toast.error(message));
                } else {
                    toast.error("Failed to update assignees");
                }
            } else {
                toast.success("Assignees updated");
            }
        });

        navigate(`../${backPath}`);
    }, [boardTicketId, currentAssigneeIds, backPath]);

    return (
        <Picker
            label="Edit assignees"
            placeholder="Filter users"
            availableItems={repoAssignees}
            currentIds={currentAssigneeIds}
            backPath={backPath}
            nameProp="username"
            icon={AssigneeAvatar}
            onSubmit={onSubmit}
            enableAfter={enableAfter}
            itemClassName="font-bold text-sm"
        />
    )
};

const EMPTY = [];

const mapStateToProps = (_, { boardTicketId }) => ({
    entities: { boardTickets, repos, tickets }
}) => {
    const boardTicket = boardTickets[boardTicketId];
    const ticket = boardTicket && tickets[boardTicket.ticket];

    const currentAssigneeIds = (boardTicket && boardTicket.assignees)
        ? boardTicket.assignees.map(({ remote_id }) => remote_id)
        : EMPTY;

    const repoId = ticket && ticket.repo;
    const { availableAssignees = EMPTY } = (repoId && repos[repoId]) || {};

    const repoAssignees = availableAssignees.map(({ remote_id: id, username }) => ({
        id,
        username,
        active: currentAssigneeIds.includes(id),
        isCurrentUser: username.localeCompare(flightPlanConfig.currentUser.username) === 0
    }));

    repoAssignees.sort((a, b) => {
        if (a.active != b.active) {
            // put the active item first - if we get here it's guaranteed
            // that if `a` is active, `b` is not, and vice-versa
            return a.active ? -1 : 1;
        } else if (a.isCurrentUser != b.isCurrentUser) {
            // put the current user above other users
            return a.isCurrentUser ? -1 : 1;
        } else {
            // both are either active or inactive, so sort by username
            // - should be case-insensitive by default
            return a.username.localeCompare(b.username);
        }
    });

    return { currentAssigneeIds, repoAssignees, repoId };
};

export default connect(
    mapStateToProps,
    { fetchAssigneesForRepo, updateAssigneesForTicket }
)(AssigneePicker);
