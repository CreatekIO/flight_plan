const handleResponse = response => {
    const { status, ok } = response;
    if (status == 204) return Promise.resolve({ success: true });

    if (ok || (status >= 400 && status < 500)) {
        return response.json().then(json => {
            const errorData = json.error || json.errors;

            if (errorData) {
                const error = new Error("Request failed");
                error.data = errorData;
                throw error;
            }

            return json;
        });
    }

    throw new Error("Request failed");
}

const createApiFunction = method => (url, body) => {
    const props = {
        method,
        headers: {
            Accept: "application/json"
        },
        credentials: "same-origin"
    };

    if (method !== "GET") {
        props.headers["Content-Type"] = "application/json";
        props.headers["X-CSRF-Token"] = Rails.csrfToken();
        props.body = JSON.stringify(body);
    }

    return fetch(url, props).then(handleResponse);
}

const safely = fn => {
    try {
        return fn();
    } catch(error) {
        if (process.env.NODE_ENV !== "production") console.warn(error);
        return null;
    }
}

export default ["GET", "POST", "PUT", "PATCH"].reduce(
    (acc, method) => ({ ...acc, [method.toLowerCase()]: createApiFunction(method) }),
    {
        addToStorage(key, item) {
            safely(() => localStorage.setItem(key, item));
        },

        removeFromStorage(key) {
            safely(() => localStorage.removeItem(key));
        }
    }
);
