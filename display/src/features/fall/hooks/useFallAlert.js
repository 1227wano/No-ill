// src/features/fall/hooks/useFallAlert.js

import { useContext } from 'react';
import { FallAlertContext } from '../context/FallAlertContext';

const useFallAlert = () => {
    const context = useContext(FallAlertContext);

    if (!context) {
        throw new Error('useFallAlert must be used within a FallAlertProvider');
    }

    return context;
};

export default useFallAlert;
