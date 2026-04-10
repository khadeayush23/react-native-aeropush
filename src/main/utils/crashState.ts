let hasCrashOccurred = false;

export const setCrashOccurred = (): void => {
  hasCrashOccurred = true;
};

export const hasCrashOccurredCheck = (): boolean => {
  return hasCrashOccurred;
};

export const resetCrashState = (): void => {
  hasCrashOccurred = false;
};
