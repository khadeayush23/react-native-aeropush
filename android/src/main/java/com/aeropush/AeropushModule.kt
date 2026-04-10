package com.aeropush

import com.facebook.react.bridge.ReactApplicationContext

class AeropushModule(reactContext: ReactApplicationContext) :
  NativeAeropushSpec(reactContext) {

  override fun multiply(a: Double, b: Double): Double {
    return a * b
  }

  companion object {
    const val NAME = NativeAeropushSpec.NAME
  }
}
