import classNames from "classnames";

const SIZES = {
    xsmall: { width: 16, thickness: 3, classes: "w-4 h-5" },
    small:  { width: 24, thickness: 4, classes: "w-5 h-5" },
    large:  { width: 56, thickness: 6, classes: "w-14 h-14" }
};

const Loading = ({ className = null, size = "small" }) => {
    const { width, thickness, classes } = SIZES[size] || SIZES.small;

    const circleProps = {
        r: (width - thickness) / 2,
        cx: width / 2,
        cy: width / 2,
        stroke: "currentColor",
        strokeWidth: thickness
    }

    const circumference = Math.PI * circleProps.r * 2;
    const arcLength = circumference / 3;

    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox={`0 0 ${width} ${width}`}
            className={classNames("animate-spin", classes, className)}
        >
            <circle {...circleProps} className="opacity-25"/>
            <circle
                {...circleProps}
                className="opacity-75"
                strokeDasharray={`${arcLength} 100`}
            />
        </svg>
    )
}

export default Loading;
