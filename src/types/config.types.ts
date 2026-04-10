export interface IAeropushConfigJson {
  uid: string;
  projectId: string;
  appToken: string;
  sdkToken: string;
  appVersion: string;
}

export enum ConfigActionKind {
  SET_CONFIG = 'SET_CONFIG',
}

export interface ISetConfig {
  type: ConfigActionKind.SET_CONFIG;
  payload: IAeropushConfigJson;
}

export type IConfigAction = ISetConfig;
