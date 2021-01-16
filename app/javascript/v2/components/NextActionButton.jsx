import React from "react";
import classNames from "classnames";

const nextActionClasses = {
    neutral: "bg-white text-gray-500 border-gray-500 hover:text-gray-600 hover:border-gray-600",
    positive: "bg-green-500 text-white border-green-500 hover:bg-green-600 hover:border-green-600",
    warning: "bg-yellow-500 text-black border-yellow-500 hover:bg-yellow-600 hover:border-yellow-600 hover:text-white",
    caution: "bg-white text-yellow-500 border-yellow-500 hover:text-yellow-600 hover:border-yellow-600",
    negative: "bg-red-500 text-white border-red-500 hover:bg-red-600 border-red-600"
};

const defaultClasses = "border py-0.5 px-1 text-xs rounded";

const SingleURLButton = ({ url, text, className }) => (
    <a
        href={url}
        className={classNames(defaultClasses, className)}
        target="_blank"
    >
        {text}
    </a>
);
;

const DownArrow = () => (
    <span
        className="align-text-top ml-0.5"
        style={{ fontSize: "70%" }}
        aria-hidden
    >
        &#9660;
    </span>
);

const MultipleURLsButton = ({ urls, text, className }) =>(
    <div className={
        classNames(
            "relative cursor-pointer group inline-block",
            defaultClasses,
            className
        )
    }>
        {text} <DownArrow/>
        <div className="w-60 absolute shadow rounded bg-white top-full left-0 hidden group-hover:block">
            {urls.map(({ url, title }) => (
                <a
                    href={url}
                    key={url}
                    target="_blank"
                    className="block px-1 py-0.5 text-gray-600 hover:text-black"
                >
                    {title || text}
                </a>
            ))}
        </div>
    </div>
);

export default function NextActionButton({ type, text, urls, className }) {
    const classes = classNames(nextActionClasses[type], className);

    return urls.length > 1
        ? <MultipleURLsButton urls={urls} text={text} className={classes} />
        : <SingleURLButton url={urls[0].url} text={text} className={classes} />
}