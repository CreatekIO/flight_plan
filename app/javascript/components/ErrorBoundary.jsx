import React from "react";

class ErrorBoundary extends React.Component {
    state = { error: null, errorInfo: null, rejection: null };

    onWindowUnhandledRejection = ({ reason }) => {
        this.setState({ rejection: reason });
    };

    componentDidCatch(error, { componentStack }) {
        this.setState({ error, componentStack });
    }

    componentDidMount() {
        window.addEventListener("unhandledrejection", this.onWindowUnhandledRejection);
    }

    componentWillUnmount() {
        window.removeEventListener("unhandledrejection", this.onWindowUnhandledRejection);
    }

    render() {
        const { error, rejection, componentStack } = this.state;
        const { children } = this.props;

        if (error || rejection) {
            const message = (error && error.message) || rejection.message;
            const stack = (error && error.stack) || rejection.stack;

            return (
                <div className="ui container">
                    <div className="ui bottom attached negative message">
                        <div className="header">Something went wrong</div>
                        {message && (
                            <p>
                                <strong>
                                    {error ? "Uncaught exception" : "Uncaught rejection"}:
                                </strong>{" "}
                                {message}
                            </p>
                        )}
                        {stack && (
                            <details>
                                <summary>Error stack</summary>
                                <pre>{stack}</pre>
                            </details>
                        )}
                        {componentStack && (
                            <details>
                                <summary>Component stack</summary>
                                <pre>{componentStack}</pre>
                            </details>
                        )}
                        <p>
                            <button
                                type="button"
                                className="ui negative small button"
                                onClick={() => location.reload()}
                            >
                                Reload the page
                            </button>
                        </p>
                    </div>
                </div>
            );
        }

        return children;
    }
}

export default ErrorBoundary;
