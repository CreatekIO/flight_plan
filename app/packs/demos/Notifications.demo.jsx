import { useEffect } from "react";
import { toast } from "react-toastify";

import Notifications from "../components/Notifications";

const onSubmit = event => {
    event.preventDefault();
    const formData = new FormData(event.target);
    const message = formData.get("message") || "Test message";
    const type = formData.get("type") || "success";

    toast(message, { type });
};

const triggerDefaultSet = () => {
    const options = { autoClose: false };

    ["success", "error", "warning", "info"].forEach(type => {
        const article = /^(a|e|i|o|u)/.test(type) ? "an" : "a";
        toast(`This is ${article} message`, { type, ...options });
    });
};

const Demo = () => {
    useEffect(triggerDefaultSet, []);

    return <>
        <form className="w-64 space-y-3 mb-8" onSubmit={onSubmit}>
            <div>
                <label className="block font-bold">
                    Message
                    <textarea
                        className="block border border-gray-500 p-1 mt-1"
                        name="message"
                        defaultValue="This is a message"
                    />
                </label>
            </div>

            <div>
                <label className="block font-bold">
                    Type
                    <select name="type" className="block border border-gray-500 p-1 mt-1">
                        <option>success</option>
                        <option>error</option>
                        <option>warning</option>
                        <option>info</option>
                    </select>
                </label>
            </div>

            <button type="submit" className="px-2 py-1 bg-blue-400 text-white rounded">Trigger</button>
        </form>

        <div className="space-x-2">
            <button onClick={() => toast.dismiss()} className="border border-gray-500 rounded px-2 py-1 text-xs">
                Clear all notifications
            </button>

            <button onClick={triggerDefaultSet} className="border border-gray-500 rounded px-2 py-1 text-xs">
                Trigger default set
            </button>
        </div>

        <Notifications />
    </>;
};

export default Demo;
