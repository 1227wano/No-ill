import { useState, useEffect, useCallback, useMemo } from 'react';
import { fetchSchedules, saveSchedule, updateSchedule, deleteSchedule } from '../services/scheduleApi';

const useSchedule = () => {
    const [scheduleItems, setScheduleItems] = useState([]);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingItem, setEditingItem] = useState(null);

    useEffect(() => {
        let ignore = false;

        const loadData = async () => {
            try {
                const data = await fetchSchedules();
                if (!ignore) {
                    setScheduleItems(data);
                }
            } catch (error) {
                console.error('Load schedules failed:', error);
            }
        };

        loadData();

        return () => {
            ignore = true;
        };
    }, []);

    const loadSchedules = useCallback(async () => {
        try {
            const data = await fetchSchedules();
            setScheduleItems(data);
        } catch (error) {
            console.error('Load schedules failed:', error);
            throw new Error('일정 목록을 불러오는데 실패했습니다.');
        }
    }, []);

    const sortedSchedules = useMemo(() => {
        const now = new Date();

        return [...scheduleItems]
            .map(item => {
                const scheduleDate = new Date(item.schTime);
                const calculatedStatus = scheduleDate < now ? 'N' : 'Y';
                return { ...item, schStatus: calculatedStatus };
            })
            .sort((a, b) => {
                return new Date(a.schTime) - new Date(b.schTime);
            });
    }, [scheduleItems]);

    const handleDelete = async (id) => {
        if (!window.confirm("정말 삭제하시겠습니까?")) return;
        try {
            await deleteSchedule(id);
            await loadSchedules(); // 삭제 후 목록 갱신
        } catch (error) {
            console.error('Delete failed:', error);
            alert('삭제에 실패했습니다.');
            throw error;
        }
    };

    const handleSave = async (formData) => {
        const today = new Date().toISOString().split('T')[0];
        const formattedTime = `${today}T${formData.time}:00`;

        const postData = {
            userNo: 1,
            schName: formData.content,
            schTime: formattedTime,
            schMemo: formData.description || ""
        };

        console.log("전송 데이터 확인:", postData);

        try {
            if (editingItem) {
                const targetId = editingItem.id;
                await updateSchedule(targetId, postData);
            } else {
                await saveSchedule(postData);
            }
            await loadSchedules();
            setIsModalOpen(false);
            setEditingItem(null);
        } catch (error) {
            console.error('Save failed:', error);
            alert('서버 저장에 실패했습니다. (미래 시간인지 확인해주세요)');
            throw error;
        }
    };

    return {
        scheduleItems: sortedSchedules,
        isModalOpen,
        handleSave,
        handleDelete,
        openModal: () => {
            setEditingItem(null);
            setIsModalOpen(true);
        },
        openModalForEdit: (item) => {
            setEditingItem(item);
            setIsModalOpen(true);
        },
        closeModal: () => {
            setIsModalOpen(false);
            setEditingItem(null);
        },
        editingItem,
        setEditingItem,
        setIsModalOpen
    };
};

export default useSchedule;