import React from "react";
import classNames from "classnames";
import { Image } from "semantic-ui-react";

const Avatar = ({ username, ...props }) => (
    <Image
        verticalAlign="middle"
        className="gh-avatar"
        {...props}
        src={`https://github.com/${username}.png`}
        alt={username}
        avatar
    />
);

export default Avatar;
