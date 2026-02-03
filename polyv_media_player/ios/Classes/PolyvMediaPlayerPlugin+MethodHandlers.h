#import "PolyvMediaPlayerPlugin.h"

@interface PolyvMediaPlayerPlugin (MethodHandlers)

- (void)handleInitialize:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleLoadVideo:(NSDictionary *)args result:(FlutterResult)result;
- (void)handlePlay:(FlutterResult)result;
- (void)handlePause:(FlutterResult)result;
- (void)handleStop:(FlutterResult)result;
- (void)handleSeekTo:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleSetPlaybackSpeed:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleSetQuality:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleSetSubtitle:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleGetQualities:(FlutterResult)result;
- (void)handleGetSubtitles:(FlutterResult)result;

- (void)handlePauseDownload:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleResumeDownload:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleRetryDownload:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleDeleteDownload:(NSDictionary *)args result:(FlutterResult)result;
- (void)handleGetDownloadList:(FlutterResult)result;
- (void)handleStartDownload:(NSDictionary *)args result:(FlutterResult)result;

- (void)clearPlayer;

@end
