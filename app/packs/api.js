const metaValue = name => () => {
    const meta = document.querySelector(`meta[name="${name}"]`);

    return meta && meta.content;
}

const csrfToken = metaValue("csrf-token");
const csrfParam = metaValue("csrf-param");

const handleResponse = response => {
    const { status, ok } = response;
    if (status == 204) return Promise.resolve({ success: true });

    if (ok || (status >= 400 && status < 500)) {
        return response.headers.get("Content-Type").startsWith("application/json")
            ? response.json()
            : response.text().then(text => ({ [ok ? "data" : "error"]: text }))
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
        props.headers["X-CSRF-Token"] = csrfToken();
        props.body = JSON.stringify(body);
    }

    return fetch(url, props).then(handleResponse);
}

export const requestAndRedirectViaBrowser = (method, url) => {
    const form = document.createElement("form");
    form.method = method;
    form.action = url;
    form.style.display = "none";
    form.innerHTML = `<input type="hidden" name="${csrfParam()}" value="${csrfToken()}"/>`;

    document.body.appendChild(form);
    form.requestSubmit();
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
        },

        deleteRequest: createApiFunction("DELETE") // `delete` is a reserved word in JS
    }
);
