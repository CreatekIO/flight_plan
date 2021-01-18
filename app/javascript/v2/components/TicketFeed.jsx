import React, { Fragment, useEffect } from "react";
import { connect } from "react-redux";
import { denormalize } from "normalizr";
import showdown from "showdown";
import classNames from "classnames";

import Avatar from "./Avatar";

const markdownConverter = new showdown.Converter();
markdownConverter.setFlavor("github");
markdownConverter.setOption("openLinksInNewWindow", true);

const Entry = ({ author = "ghost", body, timestamp, action = "commented" }) => (
    <div className="flex mb-4">
        <Avatar username={author} />

        <div className="border border-gray-300 rounded ml-3 flex-grow">
            <div className="border-b border-gray-300 bg-gray-100 px-3 py-2 font-bold text-sm">
                <a
                    href={`https://github.com/${author}`}
                    target="_blank"
                    className="text-blue-500 hover:text-blue-600"
                >
                    {author}
                </a>
                &nbsp;{action}&nbsp;
                {timestamp && (
                    <span className="text-gray-400 text-xs font-normal">
                        {timestamp} ago
                    </span>
                )}
            </div>
            <div
                className="px-4 py-3 text-sm gh-markdown"
                dangerouslySetInnerHTML={{ __html: markdownConverter.makeHtml(body)}}
            />
        </div>
    </div>
);

const TicketEntry = connect((
    { entities: { tickets }},
    { id }
) => {
    if (!id || !(id in tickets)) return {
        body: "<br/><br/><br/>",
        action: "opened issue"
    };

    const { creator: author, body, timestamp } = tickets[id];

    return {
        author,
        timestamp,
        body: body || "*No description*",
        action: "opened issue"
    };
})(Entry);

const CommentEntry = connect(
    (_, { id }) => ({ entities: { comments }}) => (id && comments[id]) || {}
)(Entry);

const Feed = ({ ticket, comments = [] }) => (
    <Fragment>
        <TicketEntry id={ticket} />
        {comments.map(id => <CommentEntry key={id} id={id} />)}
    </Fragment>
);

const mapStateToProps = (_, { id: idFromProps }) => ({
    entities: { boardTickets },
    current
}) => {
    const id = idFromProps || current.boardTicket;

    if (!id || !(id in boardTickets)) return {
        comments: []
    }

    return boardTickets[id];
}

export default connect(mapStateToProps)(Feed);