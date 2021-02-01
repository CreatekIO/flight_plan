import React, { useState, useEffect, useRef, useCallback } from "react";
import { connect } from "react-redux";
import { useNavigate } from "@reach/router";
import { useCombobox } from "downshift";
import classNames from "classnames";
import Octicon, { Check, X } from "@githubprimer/octicons-react";

import FormWrapper from "./TicketFormWrapper";
import { fetchLabelsForRepo } from "../slices/labels";
import { updateLabelsForTicket } from "../slices/board_tickets";

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions#Escaping
const escapeRegexp = text => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const isBlank = text => !/\S+/.test(text);

const {
    InputKeyDownEnter,
    ItemClick,
    InputBlur,
    ControlledPropUpdatedSelectedItem
} = useCombobox.stateChangeTypes;

const filterItems = (items, search) => {
    const matcher = new RegExp(escapeRegexp(search), "i");
    return items.filter(({ name }) => matcher.test(name));
};

const useDelayedFocus = timeout => {
    const ref = useRef(null);
    const [disabled, setDisabled] = useState(Boolean(timeout));

    useEffect(() => {
        if (!timeout) return;

        const id = setTimeout(() => {
            setDisabled(false);
            ref.current && ref.current.focus();
        }, timeout);

        return () => clearTimeout(id);
    }, []);

    return { disabled, ref };
};

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
    const [inputItems, setInputItems] = useState(repoLabels);
    const [selectedIds, setSelectedIds] = useState(currentLabelIds);

    // Since we set `isOpen = true`, Downshift will try to focus the
    // combobox input on mount. If we're being transitioned into view,
    // this will break the transition, as the browser will immediately
    // bring the input into view. To get round this, we disable the input
    // on mount so Downshift's focus-ing has no effect, then re-enable it
    // and focus ourselves after a delay, after which we assume that the
    // transition has finished
    const { disabled, ref: inputRef } = useDelayedFocus(enableAfter);

    const {
        getLabelProps, getInputProps, getComboboxProps, getMenuProps, getItemProps,
        highlightedIndex, inputValue
    } = useCombobox({
        isOpen: true,
        itemToString: item => item ? item.name : "",
        items: inputItems,
        selectedItem: null,
        onSelectedItemChange({ selectedItem, inputValue, ...props }) {
            if (!selectedItem) return;

            const { id: itemId } = selectedItem;

            setSelectedIds(selectedIds.includes(itemId)
                ? selectedIds.filter(id => id !== itemId)
                : [...selectedIds, itemId]
            );
        },
        onInputValueChange({ inputValue }) {
            setInputItems(
                isBlank(inputValue) ? repoLabels : filterItems(repoLabels, inputValue)
            );
        },
        stateReducer(state, { type, changes, ...extras }) {
            switch (type) {
                case InputKeyDownEnter:
                case ItemClick:
                    // Don't change anything, just set the `selectedItem`
                    return { ...state, selectedItem: changes.selectedItem };
                case InputBlur:
                    return { ...changes, inputValue: '' };
                case ControlledPropUpdatedSelectedItem:
                    // Don't clear search term when item selected
                    return { ...changes, inputValue: state.inputValue };
                default:
                    return changes
            }
        }
    });

    // Update items every time we get an update on repoLabels
    useEffect(() => {
        setInputItems(filterItems(repoLabels, inputValue));
    }, [repoLabels]);

    useEffect(() => { fetchLabelsForRepo(repoId) }, [repoId]);

    const navigate = useNavigate();

    const onSubmit = useCallback(() => {
        updateLabelsForTicket({
            id: boardTicketId,
            add: selectedIds.filter(id => !currentLabelIds.includes(id)),
            remove: currentLabelIds.filter(id => !selectedIds.includes(id))
        });

        navigate(backPath);
    }, [boardTicketId, currentLabelIds, selectedIds, backPath]);

    return (
        <FormWrapper
            label="Edit labels"
            labelProps={getLabelProps()}
            onSubmit={onSubmit}
            backPath={backPath}
        >
            <div className="relative">
                <div {...getComboboxProps()} className="p-3 sticky inset-x-0 top-0 bg-white border-b border-gray-300">
                    <input
                        {...getInputProps({ ref: inputRef })}
                        className="rounded border border-gray-300 text-gray-900 w-full py-1 px-3 text-sm"
                        placeholder="Filter labels"
                        disabled={disabled}
                    />
                </div>
                <ul {...getMenuProps()} className="divide-y divide-gray-300 border-b border-gray-300">
                    {inputItems.map((item, index) => {
                        const { id, name, colour } = item;
                        const isSelected = selectedIds.includes(id);

                        return (
                            <li
                                className={classNames(
                                    "px-3 py-2 flex items-center text-xs text-gray-800 cursor-pointer",
                                    { "bg-blue-100": highlightedIndex === index }
                                )}
                                key={`${id}-${index}`}
                                {...getItemProps({ item, index })}
                            >
                                {isSelected && <Octicon icon={Check} className="mr-2" />}

                                <span
                                    className={classNames(
                                        "rounded-full w-4 h-4 inline-block bg-gray-100 mr-2",
                                        { "ml-5": !isSelected }
                                    )}
                                    style={{ backgroundColor: `#${colour}` }}
                                />
                                <span className="flex-grow truncate">{name}</span>

                                {isSelected && <Octicon icon={X} />}
                            </li>
                        )})}
                </ul>
            </div>
        </FormWrapper>
    );
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
