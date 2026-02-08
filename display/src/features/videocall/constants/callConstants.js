// src/features/videocall/constants/callConstants.js

/**
 * 통화 상태
 */
export const CALL_STATE = {
    IDLE: 'idle',
    CALLING: 'calling',
    RINGING: 'ringing',
    CONNECTED: 'connected',
    ENDED: 'ended',
};

/**
 * 통화 타입
 */
export const CALL_TYPE = {
    VIDEO_CALL: 'VIDEO_CALL',
    VIDEO_CALL_INCOMING: 'VIDEO_CALL_INCOMING',
};

/**
 * OpenVidu 설정
 */
export const OPENVIDU_CONFIG = {
    RESOLUTION: '640x480',
    FRAME_RATE: 30,
    AUDIO: true,
    VIDEO: true,
    MIRROR: true,
};

/**
 * 통화 종료 딜레이 (ms)
 */
export const CALL_END_DELAY = 2000;
