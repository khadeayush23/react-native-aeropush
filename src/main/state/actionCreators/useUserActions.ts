import { useCallback } from 'react';

import { DEFAULT_ERROR_MESSAGE } from '../../constants/appConstants';
import { extractError } from '../../utils/errorUtil';
import { setUserError } from '../../state/actions/userActions';
import { setUserLoading } from '../../state/actions/userActions';
import { useApiClient } from '../../utils/useApiClient';

import { API_PATHS } from '../../constants/apiConstants';
import type { IUserAction } from '../../../types/user.types';
import type { ILoginActionPayload } from '../../../types/globalProvider.types';
import { setSdkTokenNative } from '../../utils/AeropushNativeUtils';

import type { IAeropushConfigJson } from '../../../types/config.types';

const useUserActions = (
  dispatch: React.Dispatch<IUserAction>,
  refreshConfig: () => Promise<void>,
  configState: IAeropushConfigJson
) => {
  const { getData } = useApiClient(configState);
  const clearUserLogin = (shouldClearLogin: boolean) => {
    if (shouldClearLogin) {
      setSdkTokenNative('').then(() => {
        refreshConfig();
      });
    }
  };

  const loginUser = useCallback(
    (loginPayload: ILoginActionPayload) => {
      dispatch(setUserLoading());
      getData(API_PATHS.LOGIN, {
        ...loginPayload,
        projectId: configState.projectId,
      })
        .then((loginResponse) => {
          const sdkToken = loginResponse?.data?.token as string;
          if (sdkToken) {
            setSdkTokenNative(sdkToken).then(() => {
              refreshConfig();
            });
          } else {
            dispatch(setUserError(extractError(loginResponse)));
          }
        })
        .catch(() => {
          dispatch(setUserError(DEFAULT_ERROR_MESSAGE));
        });
    },
    [dispatch, configState, getData, refreshConfig]
  );

  return {
    loginUser,
    clearUserLogin,
  };
};

export default useUserActions;
