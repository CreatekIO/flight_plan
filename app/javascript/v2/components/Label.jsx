import React from "react";
import { connect } from "react-redux";
import fontColor from "font-color-contrast";
import classNames from "classnames";

const UnwrappedLabel = ({ colour, name, bordered = false, className }) => (
    <span
        className={classNames(
            "rounded text-xs py-1 px-2 inline-block font-bold",
            className,
            { "border border-gray-200": bordered }
        )}
        style={{
            backgroundColor: `#${colour}`,
            color: fontColor(`#${colour}`)
        }}
    >
        {name}
    </span>
);

export const Milestone = connect(
    (_, { id }) => ({ entities: { milestones }}) => {
        const { title } = milestones[id];
        return { name: title, colour: "ffffff", bordered: true };
    }
)(UnwrappedLabel);

const Label = connect(
    (_, { id }) => ({ entities: { labels }}) => labels[id]
)(UnwrappedLabel);

export default Label;
