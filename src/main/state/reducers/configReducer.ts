import {
  type IAeropushConfigJson,
  type IConfigAction,
  ConfigActionKind,
} from '../../../types/config.types';

const configReducer = (
  state: IAeropushConfigJson,
  action: IConfigAction
): IAeropushConfigJson => {
  const { type } = action;
  switch (type) {
    case ConfigActionKind.SET_CONFIG:
      const { payload: setConfigPayload } = action;
      return { ...setConfigPayload };
    default:
      return state;
  }
};

export default configReducer;
