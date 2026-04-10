import React, { type ComponentType } from 'react';

import type { IWithAeropush } from '../types/utils.types';

const withAeropush: IWithAeropush = <T,>(BaseComponent: ComponentType<T>) => {
  const AeropushProvider: React.FC<React.PropsWithChildren<T>> = ({
    children,
    ...props
  }) => {
    return <BaseComponent {...(props as T)}>{children}</BaseComponent>;
  };
  return AeropushProvider;
};

export default withAeropush;
