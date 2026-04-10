import { useCallback } from 'react';

import { AEROPUSH_DISABLED_ERROR } from '../AeropushNativeModule';
import type { IUseAeropushModal } from '../types/utils.types';

const useAeropushModal = (): IUseAeropushModal => {
  const showModal = useCallback(() => {
    console.error(AEROPUSH_DISABLED_ERROR);
  }, []);
  return {
    showModal,
  };
};

export default useAeropushModal;
