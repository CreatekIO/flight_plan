import classNames from "classnames";

const SIZES = {
    mini: "h-6 w-6",    // 24px
    standard: "h-9 w-9" // 36px
};

const BIGGEST_SIZE = 36; // px, from `SIZES` above

const Avatar = ({ username = "ghost", size = "standard", className }) => (
    <img
        className={classNames(
            "rounded-full bg-gray-200",
            SIZES[size] || SIZES.standard,
            className
        )}
        src={`https://github.com/${username}.png?size=${BIGGEST_SIZE}`}
        alt={username}
    />
);

export default Avatar;
