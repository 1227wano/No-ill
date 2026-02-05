import { createContext } from 'react';

export const VideoCallContext = createContext({
    callState: 'idle',
    incomingCall: null,
    localStream: null,
    remoteStream: null,
    isMicOn: true,
    isCameraOn: true,
    startCall: () => {},
    startPetCall: () => {},
    acceptCall: () => {},
    rejectCall: () => {},
    endCall: () => {},
    toggleMic: () => {},
    toggleCamera: () => {},
});