import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  onLaunch(initParamsString: string): void;
  getAeropushConfig(): Promise<string>;
  getAeropushMeta(): Promise<string>;
  sync(): void;
  downloadStageBundle(url: string, hash: string): Promise<string>;
  popEvents(): Promise<string>;
  acknowledgeEvents(eventIds: string): void;
  toggleAeropushSwitch(switchState: string): Promise<string>;
  updateSdkToken(sdkToken: string): Promise<string>;
  restart(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Aeropush');
