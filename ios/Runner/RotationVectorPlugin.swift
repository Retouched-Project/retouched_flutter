import Flutter
import CoreMotion
import UIKit

public class RotationVectorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private let motionManager = CMMotionManager()
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(
            name: "com.ddavef.retouched/rotation_vector",
            binaryMessenger: registrar.messenger()
        )
        let instance = RotationVectorPlugin()
        channel.setStreamHandler(instance)
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard motionManager.isDeviceMotionAvailable else {
            return FlutterError(code: "NO_SENSOR", message: "Device motion not available", details: nil)
        }
        eventSink = events
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] motion, _ in
            guard let self = self, let q = motion?.attitude.quaternion else { return }
            self.eventSink?([q.x, q.y, q.z, q.w])
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopDeviceMotionUpdates()
        eventSink = nil
        return nil
    }
}
