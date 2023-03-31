import { AlertIcon } from "@primer/octicons-react";
import classNames from "classnames";

import { requestAndRedirectViaBrowser } from "../api";

const redirectToLogin = () =>
    requestAndRedirectViaBrowser("POST", "/users/auth/github?app=true");

const GitHubAppWarning = ({ verb, className }) => (
    <div className={classNames("text-xs flex", className)}>
        <AlertIcon className="mr-1 flex-none"/>
        {verb} needs
        <button className="ml-1 underline" onClick={redirectToLogin}>GitHub App login</button>
    </div>
);

export default GitHubAppWarning;
