import { useContext } from 'react';

import { GlobalContext } from '../state';
import type { IUseAeropushUpdate } from '../../types/utils.types';
import { SWITCH_STATES } from '../../types/meta.types';

export const useAeropushUpdate = (): IUseAeropushUpdate => {
  const { updateMetaState, metaState } = useContext(GlobalContext);
  return {
    isRestartRequired:
      metaState.switchState === SWITCH_STATES.PROD &&
      Boolean(metaState.prodSlot?.tempHash) &&
      Boolean(updateMetaState?.newBundle?.id),
    currentlyRunningBundle: updateMetaState?.currentlyRunningBundle,
    newReleaseBundle: updateMetaState?.newBundle,
  };
};
