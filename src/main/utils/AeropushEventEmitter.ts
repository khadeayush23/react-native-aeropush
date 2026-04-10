import type { IAeropushNativeEventData } from '../state/useAeropushEvents';

type EventListener = (data?: IAeropushNativeEventData) => void;

class EventEmitter {
  private events: EventListener[] = [];

  addEventListener(listener: EventListener): void {
    this.events.push(listener);
  }

  removeEventListener(listenerToRemove: EventListener): void {
    this.events = this.events.filter(
      (listener) => listener !== listenerToRemove
    );
  }

  emit(data?: IAeropushNativeEventData): void {
    this.events.forEach((listener) => listener(data));
  }
}

export const aeropushEventEmitter = new EventEmitter();
