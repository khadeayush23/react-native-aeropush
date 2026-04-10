import type { IUserState } from './user.types';
import type { IBucketState } from './bucket.types';
import type { IAeropushMeta } from './meta.types';
import type { IBundleState } from './bundle.types';
import type { IDownloadState } from './download.types';
import type { IUpdateMetaState } from '../main/state/reducers/updateMetaReducer';
import type { IAeropushConfigJson } from './config.types';

export interface ILoginActionPayload {
  pin: string;
}

interface IGlobalContextActions {
  setIsModalVisible: (isModalVisible: boolean) => void;
  loginUser: (loginPayload: ILoginActionPayload) => void;
  fetchBuckets: () => void;
  fetchBundles: (bucketId?: string | null, pageOffset?: string | null) => void;
  clearUserLogin: (shouldClear: boolean) => void;
  refreshMeta: () => void;
  refreshConfig: () => void;
  selectBucket: (bucketId?: string | null) => void;
  downloadBundle: (url: string, hash: string) => void;
  setProgress: (newProgress: number) => void;
  setDownloadErrorMessage: (msg: string) => void;
}

export interface IGlobalContext {
  isModalVisible: boolean;
  metaState: IAeropushMeta;
  userState: IUserState;
  bucketState: IBucketState;
  bundleState: IBundleState;
  downloadState: IDownloadState;
  updateMetaState: IUpdateMetaState;
  configState: IAeropushConfigJson;
  actions: IGlobalContextActions;
}
