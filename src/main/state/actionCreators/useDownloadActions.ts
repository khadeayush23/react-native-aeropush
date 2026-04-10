import { useCallback } from 'react';

import { downloadBundleNative } from '../../utils/AeropushNativeUtils';
import {
  setDownloadData,
  setDownloadError,
  setDownloadLoading,
} from '../actions/downloadActions';

import type { IDownloadAction } from '../../../types/download.types';
import type { IAeropushConfigJson } from '../../../types/config.types';

const useDownloadActions = (
  dispatch: React.Dispatch<IDownloadAction>,
  refreshAeropushMeta: () => void,
  configState: IAeropushConfigJson
) => {
  const downloadBundle = useCallback(
    (apiDownloadUrl: string, hash: string) => {
      dispatch(setDownloadLoading());
      const projectId = configState.projectId;
      const url = `${apiDownloadUrl}?projectId=${projectId}`;
      requestAnimationFrame(() => {
        downloadBundleNative({
          url,
          hash,
        })
          .then((_) => {
            dispatch(
              setDownloadData({
                currentProgress: 1,
              })
            );
            refreshAeropushMeta();
          })
          .catch((err) => {
            dispatch(setDownloadError(err.toString()));
          });
      });
    },
    [dispatch, refreshAeropushMeta, configState]
  );

  const setProgress = useCallback(
    (newProgress: number) => {
      dispatch(
        setDownloadData({
          currentProgress: newProgress,
        })
      );
    },
    [dispatch]
  );

  const setDownloadErrorMessage = (message: string) => {
    dispatch(setDownloadError(message));
  };

  return {
    downloadBundle,
    setProgress,
    setDownloadErrorMessage,
  };
};

export default useDownloadActions;
