import React from "react";
import classNames from "classnames";
import { Image } from "semantic-ui-react";

const Avatar = ({ username, ...props }) => (
    <Image {...props} src={`https://github.com/${username}.png`} alt={username} avatar />
);

export default Avatar;
