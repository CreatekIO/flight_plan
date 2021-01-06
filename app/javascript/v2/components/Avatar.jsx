import React from "react";
import classNames from "classnames";

const SIZES = {
    mini: "h-6 w-6"
};

const Avatar = ({ username, size, className }) => (
    <img
        className={
            classNames("rounded-full bg-gray-200", SIZES[size], className)
        }
        src={`https://github.com/${username}.png?size=48`}
        alt={username}
    />
);

export default Avatar;
