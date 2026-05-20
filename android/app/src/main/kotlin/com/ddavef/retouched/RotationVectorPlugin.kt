package com.ddavef.retouched

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

class RotationVectorPlugin : FlutterPlugin, EventChannel.StreamHandler, SensorEventListener {
    private var sensorManager: SensorManager? = null
    private var rotationSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null
    private var eventChannel: EventChannel? = null
    private val quaternion = FloatArray(4)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        eventChannel = EventChannel(binding.binaryMessenger, "com.ddavef.retouched/rotation_vector")
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        sensorManager?.unregisterListener(this)
        sensorManager = null
        rotationSensor = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val sensor = rotationSensor
        if (sensor == null) {
            events?.error("NO_SENSOR", "Rotation vector sensor not available", null)
            return
        }
        sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(this)
        eventSink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        SensorManager.getQuaternionFromVector(quaternion, event.values)
        eventSink?.success(listOf(
            quaternion[1].toDouble(),
            quaternion[2].toDouble(),
            quaternion[3].toDouble(),
            quaternion[0].toDouble()
        ))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
    }
}
