import { connect } from "react-redux";
import classNames from "classnames";

const COEFFICIENTS = [0.2126, 0.7152, 0.0722]; // [r, g, b]
const THRESHOLD = 0.38

// Algorithm from https://gist.github.com/Myndex/e1025706436736166561d339fd667493
const colourClass = bgColour => {
    const luminence = /([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i.exec(bgColour)
        .slice(1)
        .map((n, index) => Math.pow(parseInt(n, 16) / 255.0, 2.2) * COEFFICIENTS[index])
        .reduce((sum, n) => sum + n, 0);

    return luminence > THRESHOLD ? "text-black" : "text-white";
}

const UnwrappedLabel = ({ colour, name, bordered = false, className }) => (
    <span
        className={classNames(
            "rounded text-xs py-1 px-2 inline-block font-bold",
            className,
            colourClass(colour),
            { "border border-gray-200": bordered }
        )}
        style={{ backgroundColor: `#${colour}` }}
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
