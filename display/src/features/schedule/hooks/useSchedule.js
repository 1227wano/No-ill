import { useState, useEffect, useCallback, useMemo } from 'react';
import { fetchSchedules, saveSchedule, updateSchedule, deleteSchedule } from '../services/scheduleApi';

// 데이터 흐름을 관리하는 파일
/* eslint-disable react-hooks/set-state-in-effect */

const useSchedule = () => {
  const [scheduleItems, setScheduleItems] = useState([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  // 1. 일정 목록 불러오기
  const loadSchedules = useCallback(async () => {
    try {
      const data = await fetchSchedules();
      setScheduleItems(data);
    } catch (error) {
      console.error('Load schedules failed:', error);
    }
  }, []);

  // 2. 초기 로드
  useEffect(() => {
     
    loadSchedules();
  }, [loadSchedules]);

  // ⭐ 2. 실시간 상태 계산 및 정렬 로직 (이것을 반환합니다)
  const sortedSchedules = useMemo(() => {
    const now = new Date();

    return [...scheduleItems]
      .map(item => {
        // 서버의 schTime을 기준으로 실시간 상태(Y/N) 판단
        const scheduleDate = new Date(item.schTime);
        const calculatedStatus = scheduleDate < now ? 'N' : 'Y';
        return { ...item, schStatus: calculatedStatus }; // 기존 schStatus를 덮어씌움
      })
      .sort((a, b) => {
        // 시간순 정렬
        return new Date(a.schTime) - new Date(b.schTime);
      });
  }, [scheduleItems]);

  // 3. 삭제 로직
  const handleDelete = async (id) => {
    if (!window.confirm("정말 삭제하시겠습니까?")) return;
    try {
      await deleteSchedule(id);
      await loadSchedules(); // 삭제 후 목록 갱신
    } catch (error) {
      console.error('Delete failed:', error);
      alert('삭제에 실패했습니다.');
    }
  };

  // 4. 저장/수정 로직 (이 부분이 누락되어 에러가 났었습니다)
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
        // 수정 모드: id는 Long 타입이므로 editingItem.id 혹은 editingItem.id 확인
        const targetId = editingItem.id || editingItem.id;
        await updateSchedule(targetId, postData);
      } else {
        // 등록 모드
        await saveSchedule(postData);
      }
      await loadSchedules();
      setIsModalOpen(false);
      setEditingItem(null);
    } catch (error) {
      console.error('Save failed:', error);
      alert('서버 저장에 실패했습니다. (미래 시간인지 확인해주세요)');
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