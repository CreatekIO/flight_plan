import React from "react";

const nextActionClasses = {
    positive: "green",
    warning: "yellow",
    caution: "basic yellow",
    negative: "red"
};

const defaultClass = "basic";

const SingleURLButton = ({ url, text, className }) => {
    return (
        <a href={url} className={className} target="_blank">
            {text}
        </a>
    );
};

const MultipleURLsButton = ({ urls, text, className }) => {
    return (
        <div className={`${className} simple dropdown`}>
            <span className="text">{text}</span> <i className="dropdown icon" />
            <div className="menu">
                {urls.map(url => (
                    <a href={url.url} key={url.url} className="item" target="_blank">
                        {url.title || text}
                    </a>
                ))}
            </div>
        </div>
    );
};

export default function NextActionButton({ type, text, urls, className }) {
    let classes = ["ui button next-action-btn", nextActionClasses[type] || defaultClass];
    if (className) classes.push(className);

    if (urls.length > 1) {
        return (
            <MultipleURLsButton urls={urls} text={text} className={classes.join(" ")} />
        );
    } else {
        return (
            <SingleURLButton
                url={urls[0].url}
                text={text}
                className={classes.join(" ")}
            />
        );
    }
}
