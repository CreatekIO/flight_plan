import React from "react";
import { Label } from "semantic-ui-react";
import fontColor from "font-color-contrast";

const LabelList = ({ labels, milestone }) => (
    <div className="labels-wrapper">
        {milestone && (
            <Label size="small" className="milestone-label">
                {milestone.title}
            </Label>
        )}
        {labels.map(({ id, name, colour }) => (
            <Label
                key={id}
                size="small"
                className="gh-label"
                style={{ backgroundColor: `#${colour}`, color: fontColor(`#${colour}`) }}
            >
                {name}
            </Label>
        ))}
    </div>
);

export default LabelList;
