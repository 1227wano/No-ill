// src/features/fall/components/AlertInfoCard.jsx

import React from 'react';

const AlertInfoCard = ({ label, value }) => {
    return (
        <div className="bg-background rounded-card p-5">
            <p className="text-body text-text-body mb-1">{label}</p>
            <p className="text-xl font-bold text-text-main">{value}</p>
        </div>
    );
};

export default AlertInfoCard;
