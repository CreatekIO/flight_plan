import React, { Component, Fragment } from "react";
import { Modal } from "semantic-ui-react";
import showdown from "showdown";

const markdownConverter = new showdown.Converter();
markdownConverter.setFlavor("github");
markdownConverter.setOption("openLinksInNewWindow", true);

const parseMarkdown = text => ({ __html: markdownConverter.makeHtml(text) });

const TicketEvent = ({ author, body, timestamp, action, divider }) => (
    <Fragment>
        {divider && <div className="ui divider" />}
        <div className="event">
            <div className="label">
                <img src={`https://github.com/${author}.png`} />
            </div>
            <div className="content">
                <div className="summary">
                    <a
                        href={`https://github.com/${author}`}
                        target="_blank"
                        className="user"
                    >
                        {author}
                    </a>
                    &nbsp;{action}
                    <div className="date">{timestamp} ago</div>
                </div>
                <div
                    className="extra text gh-markdown"
                    dangerouslySetInnerHTML={parseMarkdown(body)}
                />
            </div>
        </div>
    </Fragment>
);

const DurationList = ({ state_durations }) => (
    <div className="item">
        <div className="header">Durations</div>
        <div className="durations">
            {state_durations.map(({ id, name, duration }) => (
                <div className="ui green fluid label" key={id}>
                    {name}
                    <div className="detail">{duration}</div>
                </div>
            ))}
        </div>
    </div>
);

export default class TicketModal extends Component {
    state = { isLoading: true, boardTicket: { ticket: {}, state_durations: [] } };

    handleOpen = () => {
        fetch(this.props.boardTicketURL)
            .then(response => response.json())
            .then(boardTicket => {
                this.setState({
                    isLoading: false,
                    boardTicket: boardTicket
                });
            });
    };

    renderFeed() {
        const { body, timestamp, creator, comments } = this.state.boardTicket.ticket;

        return (
            <div className="ui feed">
                <TicketEvent
                    author={creator}
                    body={body}
                    timestamp={timestamp}
                    action="opened issue"
                />
                {comments.map(({ id, author, body, timestamp }) => (
                    <TicketEvent
                        key={id}
                        author={author}
                        body={body}
                        timestamp={timestamp}
                        action="commented"
                        divider
                    />
                ))}
            </div>
        );
    }

    render() {
        const {
            trigger,
            ticketURL,
            number: initialNumber,
            title: initialTitle
        } = this.props;

        const {
            boardTicket,
            boardTicket: { ticket, state_durations }
        } = this.state;

        return (
            <Modal
                trigger={trigger}
                className="longer scrolling"
                closeIcon
                onOpen={this.handleOpen}
            >
                <Modal.Header>
                    <a href={ticket.html_url || ticketURL} target="_blank">
                        #{ticket.remote_number || initialNumber}
                    </a>
                    &nbsp;&nbsp;
                    {ticket.remote_title || initialTitle}
                </Modal.Header>
                <Modal.Content scrolling>
                    <div className="ui divided grid ticket-modal">
                        <div className="twelve wide column">
                            {this.state.isLoading ? (
                                <div className="ui basic segment">
                                    <div className="ui active inverted dimmer">
                                        <div className="ui text loader">Loading</div>
                                    </div>
                                </div>
                            ) : (
                                this.renderFeed()
                            )}
                        </div>
                        <div className="four wide column">
                            <div className="ticket-sidebar">
                                <div className="ui vertical text menu">
                                    {!!state_durations.length && (
                                        <DurationList state_durations={state_durations} />
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>
                </Modal.Content>
            </Modal>
        );
    }
}
