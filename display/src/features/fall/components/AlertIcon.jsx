// src/features/fall/components/AlertIcon.jsx

import React from 'react';

const AlertIcon = () => {
    return (
        <div className="inline-flex items-center justify-center w-24 h-24 bg-danger/10 rounded-full mb-6">
            <svg
                className="w-14 h-14 text-danger animate-pulse"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                aria-hidden="true"
            >
                <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
            </svg>
        </div>
    );
};

export default AlertIcon;
