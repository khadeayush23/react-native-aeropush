import {
  type IMetaAction,
  type IAeropushMeta,
  MetaActionKind,
} from '../../../types/meta.types';

const metaReducer = (
  state: IAeropushMeta,
  action: IMetaAction
): IAeropushMeta => {
  const { type } = action;
  switch (type) {
    case MetaActionKind.SET_META:
      const { payload: setMetaPayload } = action;
      return setMetaPayload;

    default:
      return state;
  }
};

export default metaReducer;
