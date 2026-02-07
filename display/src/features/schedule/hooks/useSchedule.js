// src/features/schedule/hooks/useSchedule.js

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { scheduleApi } from '../services/scheduleApi';
import useAuth from '../../auth/hooks/useAuth';

const REFRESH_INTERVAL = 30 * 1000; // 30초

const useSchedule = () => {
    const { pet } = useAuth();
    const [scheduleItems, setScheduleItems] = useState([]);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const intervalRef = useRef(null);

    // 일정 목록 조회
    const loadSchedules = useCallback(async () => {
        try {
            setError(null);
            const data = await scheduleApi.fetchSchedules();
            setScheduleItems(data);
        } catch (err) {
            console.error('일정 목록 조회 실패:', err);
            setError(err.message || '일정을 불러올 수 없습니다.');
        } finally {
            setLoading(false);
        }
    }, []);

    // 초기 로드 및 자동 갱신
    useEffect(() => {
        loadSchedules();

        // 30초마다 갱신
        intervalRef.current = setInterval(loadSchedules, REFRESH_INTERVAL);

        return () => {
            if (intervalRef.current) {
                clearInterval(intervalRef.current);
            }
        };
    }, [loadSchedules]);

    // 정렬된 일정 목록 (시간순)
    const sortedSchedules = useMemo(() => {
        const now = new Date();

        return [...scheduleItems]
            .map((item) => {
                const scheduleDate = new Date(item.schTime);
                const isPast = scheduleDate < now;

                return {
                    ...item,
                    schStatus: isPast ? 'N' : 'Y',
                    isPast,
                };
            })
            .sort((a, b) => new Date(a.schTime) - new Date(b.schTime));
    }, [scheduleItems]);

    // 일정 저장/수정
    const handleSave = useCallback(
        async (formData) => {
            if (!pet?.petId) {
                throw new Error('사용자 정보를 찾을 수 없습니다.');
            }

            // 날짜/시간 포맷팅
            const today = new Date().toISOString().split('T')[0];
            const formattedTime = `${today}T${formData.time}:00`;

            const postData = {
                schName: formData.content,
                schTime: formattedTime,
                petId: pet.petId,
                schMemo: formData.description || '',
            };

            try {
                if (editingItem) {
                    await scheduleApi.updateSchedule(editingItem.id, postData);
                } else {
                    await scheduleApi.saveSchedule(postData);
                }

                await loadSchedules();
                setIsModalOpen(false);
                setEditingItem(null);
            } catch (error) {
                console.error('일정 저장 실패:', error);
                throw error;
            }
        },
        [pet, editingItem, loadSchedules]
    );

    // 일정 삭제
    const handleDelete = useCallback(
        async (id) => {
            try {
                await scheduleApi.deleteSchedule(id);
                await loadSchedules();
            } catch (error) {
                console.error('일정 삭제 실패:', error);
                throw error;
            }
        },
        [loadSchedules]
    );

    // 모달 열기 (새 일정)
    const openModal = useCallback(() => {
        setEditingItem(null);
        setIsModalOpen(true);
    }, []);

    // 모달 열기 (수정)
    const openModalForEdit = useCallback((item) => {
        setEditingItem(item);
        setIsModalOpen(true);
    }, []);

    // 모달 닫기
    const closeModal = useCallback(() => {
        setIsModalOpen(false);
        setEditingItem(null);
    }, []);

    return {
        scheduleItems: sortedSchedules,
        loading,
        error,
        isModalOpen,
        editingItem,
        handleSave,
        handleDelete,
        openModal,
        openModalForEdit,
        closeModal,
        refetch: loadSchedules,
    };
};

export default useSchedule;
