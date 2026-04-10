import { useCallback, useEffect } from 'react';

import { getAeropushMetaNative } from '../../utils/AeropushNativeUtils';
import { setMeta } from '../actions/metaActions';

import type { IMetaAction } from '../../../types/meta.types';

const useMetaActions = (dispatch: React.Dispatch<IMetaAction>) => {
  const refreshMeta = useCallback(async () => {
    try {
      const aeropushMeta = await getAeropushMetaNative();
      dispatch(setMeta(aeropushMeta));
    } catch {}
  }, [dispatch]);

  useEffect(() => {
    refreshMeta();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return {
    refreshMeta,
  };
};

export default useMetaActions;
