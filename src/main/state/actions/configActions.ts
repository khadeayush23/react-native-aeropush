import {
  type IConfigAction,
  type IAeropushConfigJson,
  ConfigActionKind,
} from '../../../types/config.types';

export const setConfig = (newConfig: IAeropushConfigJson): IConfigAction => {
  return {
    type: ConfigActionKind.SET_CONFIG,
    payload: newConfig,
  };
};
