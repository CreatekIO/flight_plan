import { Link } from "@gatsbyjs/reach-router";

const FormWrapper = ({ onSubmit, backPath, label, labelProps, children }) => (
    <div className="flex flex-col h-full">
        <label {...labelProps} className="px-2 pb-3 border-b border-gray-300">
            {label}
        </label>

        <div className="grow bg-white overflow-auto">
            {children}
        </div>
        <div className="bg-gray-100 border-t border-gray-300 px-5 py-3 flex text-sm space-x-2 text-center">
            <Link
                to={backPath}
                className="w-full border border-gray-500 bg-white p-1 rounded"
            >
                Cancel
            </Link>
            <button
                type="button"
                className="w-full border border-blue-500 bg-blue-500 text-white p-1 rounded"
                onClick={onSubmit}
            >
                Save
            </button>
        </div>
    </div>
);

export default FormWrapper;
