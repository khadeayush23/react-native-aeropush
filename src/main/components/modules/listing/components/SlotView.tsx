import { StyleSheet, View } from 'react-native';
import React from 'react';
import {
  type IAeropushSlotData,
  SLOT_STATES,
} from '../../../../../types/meta.types';
import {
  NATIVE_CONSTANTS,
  STD_MARGIN,
} from '../../../../constants/appConstants';
import { COLORS } from '../../../../constants/colors';

interface IAeropushSlot {
  slot: SlotType;
  hash: string;
  isActive: boolean;
}

type SlotType =
  | NATIVE_CONSTANTS.DEFAULT_FOLDER_SLOT
  | NATIVE_CONSTANTS.STABLE_FOLDER_SLOT
  | NATIVE_CONSTANTS.NEW_FOLDER_SLOT
  | NATIVE_CONSTANTS.TEMP_FOLDER_SLOT;

function getSlotColor(slot: SlotType): string {
  switch (slot) {
    case NATIVE_CONSTANTS.DEFAULT_FOLDER_SLOT:
      return '#9CA3AF';
    case NATIVE_CONSTANTS.STABLE_FOLDER_SLOT:
      return '#F59E0B';
    case NATIVE_CONSTANTS.NEW_FOLDER_SLOT:
      return COLORS.indigo;
    case NATIVE_CONSTANTS.TEMP_FOLDER_SLOT:
      return COLORS.green;
  }
}

const AeropushSlot: React.FC<IAeropushSlot> = ({ slot, isActive }) => {
  return (
    <View
      style={[
        styles.slotItem,
        {
          backgroundColor: getSlotColor(slot),
          borderWidth: isActive ? 1 : 0,
        },
      ]}
    />
  );
};

const SlotView: React.FC<IAeropushSlotData> = (props) => {
  const { currentSlot, tempHash, stableHash, newHash } = props;
  const activeSlot = currentSlot as unknown as string;
  return (
    <View style={[styles.parentContainer, styles.rowContainer]}>
      <AeropushSlot
        slot={NATIVE_CONSTANTS.DEFAULT_FOLDER_SLOT}
        hash={''}
        isActive={activeSlot === SLOT_STATES.DEFAULT}
      />

      {stableHash ? (
        <AeropushSlot
          slot={NATIVE_CONSTANTS.STABLE_FOLDER_SLOT}
          hash={stableHash || ''}
          isActive={activeSlot === SLOT_STATES.STABLE}
        />
      ) : null}

      {newHash ? (
        <AeropushSlot
          slot={NATIVE_CONSTANTS.NEW_FOLDER_SLOT}
          hash={newHash || ''}
          isActive={activeSlot === SLOT_STATES.NEW}
        />
      ) : null}

      {tempHash ? (
        <AeropushSlot
          slot={NATIVE_CONSTANTS.TEMP_FOLDER_SLOT}
          hash={tempHash || ''}
          isActive={false}
        />
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  parentContainer: {
    justifyContent: 'flex-start',
    alignItems: 'center',
    flexDirection: 'row',
    width: '100%',
    paddingRight: STD_MARGIN,
    paddingVertical: STD_MARGIN,
    backgroundColor: COLORS.white,
  },
  rowContainer: {
    flexDirection: 'row',
  },
  slotItem: {
    flex: 1,
    width: '100%',
    height: STD_MARGIN,
    marginLeft: STD_MARGIN,
    borderRadius: STD_MARGIN / 2,
  },
});

export default SlotView;
