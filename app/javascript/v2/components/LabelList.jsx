import React from "react";
import fontColor from "font-color-contrast";
import classNames from "classnames";

const Label = ({ colour, name, bordered = false, fullWidth = false, isLast = false }) => (
    <span
        className={classNames(
            "rounded text-xs py-1 px-2 inline-block font-bold",
            { "border border-gray-200": bordered, "w-full": fullWidth, "mr-1": !isLast }
        )}
        style={{
            backgroundColor: `#${colour}`,
            color: fontColor(`#${colour}`)
        }}
    >
        {name}
    </span>
);

const LabelList = ({ labels, milestone, noLabels, noMilestone, fullWidth }) => (
    <div className="space-y-1">
        {milestone ? (
            <Label
                colour="ffffff"
                name={milestone.title}
                bordered
                fullWidth={fullWidth}
                isLast={labels.length === 0}
            />
        ) : (
            noMilestone
        )}
        {labels.length
            ? labels.map(({ id, name, colour }, index) => (
                <Label
                    key={id}
                    name={name}
                    colour={colour}
                    fullWidth={fullWidth}
                    isLast={index === labels.length - 1}
                />
            ))
            : noLabels}
    </div>
);

LabelList.defaultProps = {
    labels: [],
    noMilestones: null,
    noLabels: null,
    fullWidth: false
};

export default LabelList;
