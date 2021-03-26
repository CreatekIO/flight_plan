import React, { useEffect, useRef } from "react";
import Octicon, { Clock } from "@githubprimer/octicons-react";
import classNames from "classnames";

import { useEntity } from "../hooks";

const HarvestButton = ({ ticketId }) => {
    useEffect(() => {
        if (document.querySelector("script[data-platform-config]")) return;

        const script = document.createElement("script");
        script.src = "https://platform.harvestapp.com/assets/platform.js";
        script.dataset.platformConfig = JSON.stringify({
            applicationName: "GitHub",
            skipStyling: true
        });
        document.head.appendChild(script);
    }, []);

    const ref = useRef(null);

    const { number, title, repo: repoId } = useEntity("ticket", ticketId);
    const { slug } = useEntity("repo", repoId);
    const [_, repoName] = slug.split("/");

    useEffect(() => {
        const harvest = document.querySelector("#harvest-messaging");
        if (!harvest) return;
        if (!ref.current) return;

        const event = new CustomEvent("harvest-event:timers:add", {
            detail: { element: ref.current }
        });

        harvest.dispatchEvent(event);
    }, [ref.current]);

    return (
        <button
            ref={ref}
            type="button"
            className={classNames(
                "block w-full text-xs text-gray-500 border border-gray-300 rounded px-4 py-1",
                "hover:text-harvest-orange hover:border-harvest-orange"
            )}
            data-item={JSON.stringify({ id: number, name: `#${number}: ${title}` })}
            data-group={JSON.stringify({ id: repoName, name: repoName })}
            data-permalink={`https://github.com/${slug}/issues/${number}`}
        >
            <Octicon icon={Clock} className="mr-2" />
            {" "}
            Track time with Harvest
        </button>
    );
}

export default HarvestButton;
