import React from "react";

export default function SwimlaneTransitionButton({ transitions }) {
    const [first, ...rest] = transitions;

    return (
        <div className="ui right floated primary compact small buttons">
            <a href={first.url} data-method="patch" className="ui button">
                {first.name}
            </a>
            {rest.length && (
                <div className="ui simple dropdown icon button">
                    <i className="dropdown icon" />
                    <div className="left menu">
                        {rest.map(transition => (
                            <a
                                href={transition.url}
                                data-method="patch"
                                className="item"
                                key={transition.id}
                            >
                                {transition.name}
                            </a>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
}
