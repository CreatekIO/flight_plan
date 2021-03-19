import React from "react";

export const ErrorDisplay = ({ error, componentStack }) => {
    const message = (error && error.message) || "Unknown error";
    const stack = (error && error.stack);

    return (
        <div className="container mx-auto bg-red-50 text-red-800 px-12 pt-8 pb-12 space-y-4 mb-20 rounded-b-xl border border-red-800 border-t-0">
            <h1 className="text-3xl">Something went wrong</h1>
            {message && (
                <p>
                    <strong>Uncaught exception:</strong>
                    {" "}
                    {message}
                </p>
            )}
            {Boolean(stack) && (
                <details>
                    <summary>Error stack</summary>
                    <pre className="max-width-full overflow-auto p-2 text-sm">{stack}</pre>
                </details>
            )}
            {Boolean(componentStack) && (
                <details>
                    <summary>Component stack</summary>
                    <pre className="max-width-full overflow-auto p-2 text-sm">{componentStack}</pre>
                </details>
            )}
            <p>
                <button
                    type="button"
                    className="bg-white text-red-800 py-2 px-4 rounded border border-red-800 hover:bg-gray-50"
                    onClick={() => location.reload()}
                >
                    Reload the page
                </button>
            </p>
        </div>
    );
};

class ErrorBoundary extends React.Component {
    state = { error: null, componentStack: null };

    componentDidCatch(error, { componentStack }) {
        this.setState({ error, componentStack });
    }

    render() {
        const { error, componentStack } = this.state;
        const { children } = this.props;

        if (!error) return children;

        return <ErrorDisplay error={error} componentStack={componentStack} />;
    }
}

export default ErrorBoundary;
