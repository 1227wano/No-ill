import { useContext } from 'react';
import { VideoCallContext } from '../context/VideoCallContext';

const useVideoCall = () => {
    const context = useContext(VideoCallContext);

    if (!context) {
        throw new Error('useVideoCall must be used within a VideoCallProvider');
    }

    return context;
};

export default useVideoCall;
