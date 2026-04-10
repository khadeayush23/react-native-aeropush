import AeropushNativeModule from '../../AeropushNativeModule';

import type {
  TDownloadBundleNative,
  TSetSdkTokenNative,
  TGetAeropushMetaNative,
  TToggleAeropushSwitchNative,
  TOnLaunchBundleNative,
  TGetAeropushConfigNative,
} from '../../types/utils.types';

export const setSdkTokenNative: TSetSdkTokenNative =
  AeropushNativeModule?.updateSdkToken;

export const getAeropushMetaNative: TGetAeropushMetaNative = () => {
  return new Promise((resolve, reject) => {
    AeropushNativeModule?.getAeropushMeta()
      .then((metaString: string) => {
        try {
          resolve(JSON.parse(metaString));
        } catch {
          reject('invalid meta string');
        }
      })
      .catch(() => {
        reject('failed to fetch meta string');
      });
  });
};

export const getAeropushConfigNative: TGetAeropushConfigNative = () => {
  return new Promise((resolve, reject) => {
    AeropushNativeModule?.getAeropushConfig()
      .then((configString: string) => {
        try {
          resolve(JSON.parse(configString));
        } catch {
          reject('invalid config string');
        }
      })
      .catch(() => {
        reject('failed to fetch config string');
      });
  });
};

export const toggleAeropushSwitchNative: TToggleAeropushSwitchNative =
  AeropushNativeModule?.toggleAeropushSwitch;

export const downloadBundleNative: TDownloadBundleNative =
  AeropushNativeModule?.downloadStageBundle;

export const onLaunchNative: TOnLaunchBundleNative =
  AeropushNativeModule?.onLaunch;

export const sync: () => void = AeropushNativeModule?.sync;

export const popEventsNative: () => Promise<string> =
  AeropushNativeModule?.popEvents;

export const acknowledgeEventsNative: (eventIds: string) => Promise<string> =
  AeropushNativeModule?.acknowledgeEvents;

export const restart = () => {
  AeropushNativeModule?.restart?.();
};
