// src/features/fall/components/AlertImage.jsx

import React from 'react';
import { getImageDataUrl } from '../utils/fallUtils';

const AlertImage = ({ imageBase64 }) => {
    const imageUrl = getImageDataUrl(imageBase64);

    if (!imageUrl) return null;

    return (
        <div className="mb-8 rounded-card overflow-hidden border-4 border-danger/30">
            <img
                src={imageUrl}
                alt="낙상 감지 이미지"
                className="w-full h-72 object-cover"
            />
        </div>
    );
};

export default AlertImage;
