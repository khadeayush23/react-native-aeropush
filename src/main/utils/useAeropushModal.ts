import { useContext, useCallback } from 'react';

import { GlobalContext } from '../../main/state';
import type { IUseAeropushModal } from '../../types/utils.types';

const useAeropushModal = (): IUseAeropushModal => {
  const {
    actions: { setIsModalVisible, refreshMeta },
  } = useContext(GlobalContext);
  const showModal = useCallback(() => {
    setIsModalVisible(true);
    refreshMeta();
  }, [setIsModalVisible, refreshMeta]);
  return {
    showModal,
  };
};

export default useAeropushModal;
