import React from "react";
import { Label } from "semantic-ui-react";
import fontColor from "font-color-contrast";
import classNames from "classnames";

const LabelList = ({ labels, milestone, noLabels, noMilestone, fullWidth }) => (
    <div className={classNames("labels-wrapper", { "ui fluid labels": fullWidth })}>
        {milestone ? (
            <Label size="small" className="milestone-label">
                {milestone.title}
            </Label>
        ) : (
            noMilestone
        )}
        {labels.length
            ? labels.map(({ id, name, colour }) => (
                  <Label
                      key={id}
                      size="small"
                      className="gh-label"
                      style={{
                          backgroundColor: `#${colour}`,
                          color: fontColor(`#${colour}`)
                      }}
                  >
                      {name}
                  </Label>
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
