// src/features/fall/context/FallAlertContext.js

import { createContext } from 'react';

export const FallAlertContext = createContext({
    fallAlert: null,
    dismissAlert: () => {},
    isConnected: false,
});
