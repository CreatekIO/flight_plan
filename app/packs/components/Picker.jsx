import { useState, useEffect, useRef, useCallback } from "react";
import { useCombobox } from "downshift";
import classNames from "classnames";
import { CheckIcon, XIcon } from "@primer/octicons-react";

import FormWrapper from "./TicketFormWrapper";

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions#Escaping
const escapeRegexp = text => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const isBlank = text => !/\S+/.test(text);

const {
    InputKeyDownEnter,
    ItemClick,
    InputBlur,
    ControlledPropUpdatedSelectedItem
} = useCombobox.stateChangeTypes;

const filterItems = (items, nameProp, search) => {
    const matcher = new RegExp(escapeRegexp(search), "i");
    return items.filter(item => matcher.test(item[nameProp]));
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

const Picker = ({
    label,
    placeholder,
    currentIds,
    availableItems, // the complete set of items available for selection
    backPath,
    icon: Icon,
    enableAfter,
    nameProp,
    onSubmit,
    itemClassName
}) => {
    const [inputItems, setInputItems] = useState(availableItems);
    const [selectedIds, setSelectedIds] = useState(currentIds);

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
        itemToString: item => item ? item[nameProp] : "",
        items: inputItems,
        selectedItem: null,
        onSelectedItemChange({ selectedItem, inputValue }) {
            if (!selectedItem) return;

            const { id: itemId } = selectedItem;

            setSelectedIds(selectedIds.includes(itemId)
                ? selectedIds.filter(id => id !== itemId)
                : [...selectedIds, itemId]
            );
        },
        onInputValueChange({ inputValue }) {
            setInputItems(
                isBlank(inputValue) ? availableItems : filterItems(availableItems, nameProp, inputValue)
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

    // Update items every time we get an update on availableItems
    useEffect(() => {
        setInputItems(filterItems(availableItems, nameProp, inputValue));
    }, [availableItems, nameProp]);

    const wrappedSubmit = useCallback(() => {
        onSubmit(selectedIds);
    }, [onSubmit, selectedIds]);

    return (
        <FormWrapper
            label={label}
            labelProps={getLabelProps()}
            onSubmit={wrappedSubmit}
            backPath={backPath}
        >
            <div className="relative">
                <div {...getComboboxProps()} className="p-3 sticky inset-x-0 top-0 bg-white border-b border-gray-300">
                    <input
                        {...getInputProps({ ref: inputRef })}
                        className="rounded border border-gray-300 text-gray-900 w-full py-1 px-3 text-sm"
                        placeholder={placeholder}
                        disabled={disabled}
                    />
                </div>
                <ul {...getMenuProps()} className="divide-y divide-gray-300 border-b border-gray-300">
                    {inputItems.map((item, index) => {
                        const { id } = item;
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
                                {isSelected && <CheckIcon className="mr-2" />}

                                {Icon && <Icon isSelected={isSelected} item={item} />}
                                <span className={classNames("flex-grow truncate", itemClassName)}>
                                    {item[nameProp]}
                                </span>

                                {isSelected && <XIcon />}
                            </li>
                        )})}
                </ul>
            </div>
        </FormWrapper>
    );
};

export default Picker;
