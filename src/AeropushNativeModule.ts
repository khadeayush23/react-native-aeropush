import { NativeModules } from 'react-native';

export const AEROPUSH_DISABLED_ERROR =
  'Aeropush is disabled or not linked correctly, falling back to noop version.';

const AeropushNativeModule = NativeModules.Aeropush;

export default AeropushNativeModule;
