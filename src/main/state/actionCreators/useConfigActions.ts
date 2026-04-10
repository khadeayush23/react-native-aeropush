import { useCallback, useEffect } from 'react';

import { getAeropushConfigNative } from '../../utils/AeropushNativeUtils';

import type { IConfigAction } from '../../../types/config.types';
import { setConfig } from '../actions/configActions';

const useConfigActions = (dispatch: React.Dispatch<IConfigAction>) => {
  const refreshConfig = useCallback(async () => {
    try {
      const aeropushConfig = await getAeropushConfigNative();
      dispatch(setConfig(aeropushConfig));
    } catch {}
  }, [dispatch]);

  useEffect(() => {
    refreshConfig();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return {
    refreshConfig,
  };
};

export default useConfigActions;
