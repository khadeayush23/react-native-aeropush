import React, { type ComponentType } from 'react';

import GlobalProvider from '../state';
import ErrorBoundary from './ErrorBoundary';

import AeropushModal from '../components/modules/modal/AeropushModal';
import type { IAeropushInitParams } from '../../types/utils.types';

const withAeropush = <T,>(
  BaseComponent: ComponentType<T>,
  initPrams?: IAeropushInitParams
) => {
  const AeropushProvider: React.FC<React.PropsWithChildren<T>> = ({
    children,
    ...props
  }) => {
    return (
      <ErrorBoundary>
        <GlobalProvider aeropushInitParams={initPrams}>
          <BaseComponent {...(props as T)}>{children}</BaseComponent>
          <AeropushModal />
        </GlobalProvider>
      </ErrorBoundary>
    );
  };
  return AeropushProvider;
};

export default withAeropush;
