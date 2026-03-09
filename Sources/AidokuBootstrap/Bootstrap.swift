import AidokuCore
import AidokuAppleAdapters
import AidokuAndroidAdapters

public enum AidokuPlatform: Sendable {
    case apple
    case android
}

public enum AidokuBootstrap {
    public static func make(platform: AidokuPlatform) -> AidokuPlatformServices {
        switch platform {
            case .apple:
                AppleAdapterFactory.makeServices()
            case .android:
                AndroidAdapterFactory.makeServices()
        }
    }
}
