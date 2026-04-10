import {
  type IMetaAction,
  type IAeropushMeta,
  MetaActionKind,
} from '../../../types/meta.types';

export const setMeta = (newMeta: IAeropushMeta): IMetaAction => {
  return {
    type: MetaActionKind.SET_META,
    payload: newMeta,
  };
};
