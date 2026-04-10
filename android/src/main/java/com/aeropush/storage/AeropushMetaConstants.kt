package com.aeropush.storage

enum class SwitchState(val value: String) {
    PROD("PROD"),
    STAGE("STAGE");

    companion object {
        fun fromValue(value: String): SwitchState {
            return entries.find { it.value == value } ?: PROD
        }
    }
}

enum class SlotState(val value: String) {
    STABLE("STABLE_SLOT"),
    NEW("NEW_SLOT"),
    DEFAULT("DEFAULT_SLOT");

    companion object {
        fun fromValue(value: String): SlotState {
            return entries.find { it.value == value } ?: DEFAULT
        }
    }
}
