export enum SWITCH_STATES {
  PROD = 'PROD',
  STAGE = 'STAGE',
}

export enum SLOT_STATES {
  STABLE = 'STABLE_SLOT',
  NEW = 'NEW_SLOT',
  DEFAULT = 'DEFAULT_SLOT',
}

export interface IAeropushSlotData {
  currentSlot: SLOT_STATES;
  stableHash?: string;
  newHash?: string;
  tempHash?: string;
}

export interface IAeropushMeta {
  switchState: SWITCH_STATES;
  prodSlot: IAeropushSlotData;
  stageSlot: IAeropushSlotData;
}

export enum MetaActionKind {
  SET_META = 'SET_META',
  GET_META = 'GET_META',
}

export interface ISetMeta {
  type: MetaActionKind.SET_META;
  payload: IAeropushMeta;
}

export type IMetaAction = ISetMeta;
