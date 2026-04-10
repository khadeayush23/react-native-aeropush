import AeropushNativeModule, {
  AEROPUSH_DISABLED_ERROR,
} from './AeropushNativeModule';

// noop imports
import withAeropushNoop from './noop/withAeropush';
import useAeropushModalNoop from './noop/useAeropushModal';

// main imports
import withAeropushMain from './main/utils/withAeropush';
import useAeropushModalMain from './main/utils/useAeropushModal';

import type { IUseAeropushModal, IWithAeropush } from './types/utils.types';
import { aeropushEventEmitter } from './main/utils/AeropushEventEmitter';

export let withAeropush: IWithAeropush;
export let useAeropushModal: () => IUseAeropushModal;

if (AeropushNativeModule?.getAeropushConfig) {
  withAeropush = withAeropushMain;
  useAeropushModal = useAeropushModalMain;
} else {
  console.warn(AEROPUSH_DISABLED_ERROR);
  withAeropush = withAeropushNoop;
  useAeropushModal = useAeropushModalNoop;
}

export { sync, restart } from './main/utils/AeropushNativeUtils';
export { useAeropushUpdate } from './main/utils/useAeropushUpdate';
export const addEventListener =
  aeropushEventEmitter.addEventListener.bind(aeropushEventEmitter);
export const removeEventListener =
  aeropushEventEmitter.removeEventListener.bind(aeropushEventEmitter);
