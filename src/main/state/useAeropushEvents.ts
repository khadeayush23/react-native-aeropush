import { useEffect, useCallback, useMemo } from 'react';
import { NativeEventEmitter } from 'react-native';
import {
  NativeEventTypesProd,
  AEROPUSH_NATIVE_EVENT,
  NativeEventTypesStage,
  DEFAULT_AEROPUSH_PARAMS,
} from '../constants/appConstants';
import { aeropushEventEmitter } from '../utils/AeropushEventEmitter';
import {
  acknowledgeEventsNative,
  onLaunchNative,
  popEventsNative,
} from '../utils/AeropushNativeUtils';
import { hasCrashOccurredCheck } from '../utils/crashState';
import AeropushNativeModule from '../../AeropushNativeModule';
import type { IAeropushConfigJson } from '../../types/config.types';
import { useApiClient } from '../utils/useApiClient';
import { API_PATHS } from '../constants/apiConstants';
import debounce from '../utils/debounce';
import type { IAeropushInitParams } from '../../types/utils.types';
import {
  type IUpdateMetaAction,
  UpdateMetaActionKind,
} from '../../types/updateMeta.types';

const REFRESH_META_EVENTS: {
  [key: string]: boolean;
} = {
  [NativeEventTypesProd.DOWNLOAD_COMPLETE_PROD]: true,
  [NativeEventTypesProd.ROLLED_BACK_PROD]: true,
  [NativeEventTypesProd.AUTO_ROLLED_BACK_PROD]: true,
  [NativeEventTypesProd.STABILIZED_PROD]: true,
  [NativeEventTypesStage.DOWNLOAD_COMPLETE_STAGE]: true,
  [NativeEventTypesStage.DOWNLOAD_ERROR_STAGE]: true,
  [NativeEventTypesStage.INSTALLED_STAGE]: true,
};

export interface IAeropushNativeEventData {
  type: NativeEventTypesProd | NativeEventTypesStage;
  eventId: string;
  eventTimestamp: number;
  releaseHash?: string;
  error?: string;
  progress?: string;
}

const AEROPUSH_EVENT_DEBOUNCE_INTERVAL = 3000; // 3s

const processAeropushEvent = (
  eventString: string
): null | IAeropushNativeEventData => {
  try {
    return JSON.parse(eventString) as IAeropushNativeEventData;
  } catch {
    return null;
  }
};

export const useAeropushEvents = (
  refreshMeta: () => Promise<void>,
  setProgress: (newProgress: number) => void,
  configState: IAeropushConfigJson,
  updateMetaDispatch: React.Dispatch<IUpdateMetaAction>,
  aeropushInitParams?: IAeropushInitParams
) => {
  const { getData } = useApiClient(configState);

  const syncAeropushEvents = useCallback(
    (aeropushEvents: IAeropushNativeEventData[]) => {
      if (configState?.projectId) {
        getData(API_PATHS.LOG_EVENTS, {
          projectId: configState.projectId,
          eventData: aeropushEvents,
        }).then((res) => {
          if (res?.success) {
            try {
              const eventIds = aeropushEvents.map((event) => event.eventId);
              const eventIdString = JSON.stringify(eventIds);
              acknowledgeEventsNative(eventIdString);
            } catch {}
          }
        });
      }
    },
    [getData, configState]
  );

  const popEvents = useCallback(() => {
    popEventsNative().then((eventsString: string) => {
      try {
        const eventsArr: IAeropushNativeEventData[] = JSON.parse(eventsString);
        if (eventsArr?.length) {
          syncAeropushEvents(eventsArr);
          requestAnimationFrame(refreshMeta);
        }
      } catch {}
    });
  }, [syncAeropushEvents, refreshMeta]);

  const popEventsDebounced = useMemo(
    () => debounce(popEvents, AEROPUSH_EVENT_DEBOUNCE_INTERVAL),
    [popEvents]
  );

  useEffect(() => {
    const eventEmitter = new NativeEventEmitter(AeropushNativeModule);
    eventEmitter.addListener(AEROPUSH_NATIVE_EVENT, (nativeEventString) => {
      const eventData = processAeropushEvent(nativeEventString as string);
      if (!eventData) return;

      const eventType = eventData?.type as string;
      if (REFRESH_META_EVENTS[eventType]) {
        requestAnimationFrame(refreshMeta);
        popEventsDebounced();
      }
      switch (eventType) {
        case NativeEventTypesProd.DOWNLOAD_STARTED_PROD:
          updateMetaDispatch({
            type: UpdateMetaActionKind.SET_PENDING_RELEASE_HASH,
            payload: eventData?.releaseHash || '',
          });
          aeropushEventEmitter.emit(eventData);
          break;
        case NativeEventTypesProd.DOWNLOAD_PROGRESS_PROD:
        case NativeEventTypesProd.DOWNLOAD_COMPLETE_PROD:
        case NativeEventTypesProd.DOWNLOAD_ERROR_PROD:
        case NativeEventTypesProd.INSTALLED_PROD:
        case NativeEventTypesProd.SYNC_ERROR_PROD:
        case NativeEventTypesProd.ROLLED_BACK_PROD:
        case NativeEventTypesProd.STABILIZED_PROD:
        case NativeEventTypesProd.EXCEPTION_PROD:
        case NativeEventTypesProd.AUTO_ROLLED_BACK_PROD:
          aeropushEventEmitter.emit(eventData);
          break;
        case NativeEventTypesStage.DOWNLOAD_PROGRESS_STAGE:
          try {
            const progress = Number(eventData?.progress);
            if (progress) {
              setProgress(progress);
            }
          } catch {}
          break;
      }
    });
    return () => {
      eventEmitter.removeAllListeners(AEROPUSH_NATIVE_EVENT);
    };
  }, [refreshMeta, setProgress, popEventsDebounced, updateMetaDispatch]);

  useEffect(() => {
    setTimeout(() => {
      if (hasCrashOccurredCheck()) {
        console.warn(
          'React Native Aeropush: Skipping onLaunchNative due to JS crash'
        );
        return;
      }
      if (aeropushInitParams) {
        try {
          onLaunchNative(JSON.stringify(aeropushInitParams));
        } catch {
          throw new Error('React Native Aeropush: Invalid init params');
        }
      } else {
        onLaunchNative(JSON.stringify(DEFAULT_AEROPUSH_PARAMS));
      }
    }, 100);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    popEventsDebounced();
  }, [popEventsDebounced]);
};
