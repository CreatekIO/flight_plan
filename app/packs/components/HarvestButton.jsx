import { useEffect, useState, useRef, useCallback } from "react";
import Octicon, { Clock } from "@githubprimer/octicons-react";
import classNames from "classnames";

import Loading from "./Loading";
import { useEntity } from "../hooks";

//===== Reference =====
// - Harvest's docs:
//   @ https://github.com/harvesthq/platform/blob/master/button.md
// - Source of the Harvest Chrome extension:
//   @ https://robwu.nl/crxviewer/?crx=https%3A%2F%2Fchrome.google.com%2Fwebstore%2Fdetail%2Fharvest-time-tracker%2Ffbpiglieekigmkeebmeohkelfpjjlaia
//   (specifically `js/profiles/github.js`)
//=====================

const notifyHarvestOfButton = event => new Promise((resolve, reject) => {
    const { target: element, type } = event;

    const harvest = document.querySelector("#harvest-messaging");
    if (!harvest) return reject();

    // Instruct Harvest to add its `click` listener
    harvest.dispatchEvent(
        new CustomEvent("harvest-event:timers:add", { detail: { element }})
    );

    // Re-dispatch click event so that Harvest's `click` listener is triggered
    element.dispatchEvent(new MouseEvent(type, event));
    resolve();
});

const loadHarvestScript = () => new Promise((resolve, reject) => {
    if (document.querySelector("script[data-platform-config]")) return resolve();

    const script = document.createElement("script");
    script.src = "https://platform.harvestapp.com/assets/platform.js";
    script.dataset.platformConfig = JSON.stringify({
        applicationName: "GitHub",
        skipStyling: true
    });
    document.head.appendChild(script);

    const onReady = () => {
        document.body.removeEventListener("harvest-event:ready", onReady);
        resolve();
    };

    document.body.addEventListener("harvest-event:ready", onReady);
});

const useAttributesObserver = ({ ignore = [] }) => {
    const ref = useRef(null);
    const [extraAttributes, setExtraAttributes] = useState({});

    useEffect(() => {
        if (!ref.current) return;

        const observer = new MutationObserver(records => {
            const changes = {};
            for (const { attributeName, target } of records) {
                if (!ignore.includes(attributeName)) {
                    changes[attributeName] = target.getAttribute(attributeName);
                }
            }

            setExtraAttributes(previous => ({ ...previous, ...changes }));
        });

        observer.observe(ref.current, { attributes: true })
        return () => observer.disconnect();
    }, [ref.current, ...ignore]);

    return { ref, ...extraAttributes };
};

const HarvestButton = ({ ticketId }) => {
    const [harvestState, setHarvestState] = useState("idle");

    const onClick = useCallback(({ nativeEvent }) => {
        setHarvestState("loading");

        loadHarvestScript()
            .then(() => notifyHarvestOfButton(nativeEvent))
            .then(() => setHarvestState("loaded"));
    }, [setHarvestState]);

    const { number, title, repo: repoId } = useEntity("ticket", ticketId);
    const { slug } = useEntity("repo", repoId);
    const [_, repoName] = slug.split("/");

    const extraProps = useAttributesObserver({ ignore: ["class"] });

    return (
        <button
            onClick={onClick}
            type="button"
            className={classNames(
                "block w-full flex items-center justify-center text-xs text-gray-500 border border-gray-300 rounded px-4",
                "hover:text-harvest-orange hover:border-harvest-orange",
                harvestState === "loading" ? "py-1" : "py-1.5"
            )}
            data-item={JSON.stringify({ id: number, name: `#${number}: ${title}` })}
            data-group={JSON.stringify({ id: repoName, name: repoName })}
            data-permalink={`https://github.com/${slug}/issues/${number}`}
            {...extraProps}
        >
            {harvestState === "loading"
                ? <Loading size="xsmall" className="inline-block mr-2" />
                : <Octicon icon={Clock} className="mr-2.5" />
            }
            {" "}
            Track time with Harvest
        </button>
    );
}

export default HarvestButton;
