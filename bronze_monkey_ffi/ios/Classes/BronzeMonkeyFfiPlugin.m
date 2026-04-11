#import "BronzeMonkeyFfiPlugin.h"

@implementation BronzeMonkeyFfiPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  bm_library_init();
}
@end
