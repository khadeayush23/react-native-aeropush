import type { NativeSyntheticEvent } from 'react-native';
import type { IUpdateMeta } from './updateMeta.types';
import type { IAeropushMeta } from './meta.types';
import { type SWITCH_STATES } from './meta.types';
import type { IAeropushConfigJson } from './config.types';

interface IBundleInfo {
  url: string;
  hash: string;
}

export interface IAeropushInitParams {}

export type IWithAeropush = (
  BaseComponent: React.ComponentType,
  initPrams?: IAeropushInitParams
) => React.ComponentType;

export interface IAeropushConfig {
  aeropushEnabled: boolean;
  projectId: string;
}

export interface IUseAeropushModal {
  showModal: () => void;
}

export type TextChangeEventType = NativeSyntheticEvent<{ text: string }>;

export type TSetSdkTokenNative = (sdkToken: string) => Promise<string>;

export type TGetAeropushMetaNative = () => Promise<IAeropushMeta>;

export type TGetAeropushConfigNative = () => Promise<IAeropushConfigJson>;

export type TToggleAeropushSwitchNative = (
  switchState: SWITCH_STATES
) => Promise<string>;

export type TDownloadBundleNative = (
  bundleInfo: IBundleInfo
) => Promise<string>;

export type TOnLaunchBundleNative = (aeropushInitParams: string) => void;

export interface IUseAeropushUpdate {
  isRestartRequired: boolean;
  currentlyRunningBundle: IUpdateMeta | null;
  newReleaseBundle: IUpdateMeta | null;
}
