// Screen capture through ScreenCaptureKit, exposed as plain C functions
// for Spinel's FFI (spinel_studio/platform/screen_capture.rb).
//
// A stream keeps the newest frame of the main display in NV12, leaving
// out one window (the app's toolbar). A screenshot gives one BGRA image.

#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <CoreMedia/CoreMedia.h>
#import <AppKit/AppKit.h>
#include <pthread.h>

static pthread_mutex_t frame_lock = PTHREAD_MUTEX_INITIALIZER;
static uint8_t *latest_frame;
static long frame_width, frame_height, frames_arrived;

@interface StudioFrameSink : NSObject <SCStreamOutput>
@end

@implementation StudioFrameSink
- (void)stream:(SCStream *)stream didOutputSampleBuffer:(CMSampleBufferRef)sample ofType:(SCStreamOutputType)type {
  if (type != SCStreamOutputTypeScreen) return;
  CVPixelBufferRef pixels = CMSampleBufferGetImageBuffer(sample);
  if (!pixels) return;  // an idle frame: the screen did not change
  CVPixelBufferLockBaseAddress(pixels, kCVPixelBufferLock_ReadOnly);
  pthread_mutex_lock(&frame_lock);
  for (size_t plane = 0; plane < 2; plane++) {
    const uint8_t *source = CVPixelBufferGetBaseAddressOfPlane(pixels, plane);
    size_t stride = CVPixelBufferGetBytesPerRowOfPlane(pixels, plane);
    long rows = plane == 0 ? frame_height : frame_height / 2;
    uint8_t *target = latest_frame + (plane == 0 ? 0 : frame_width * frame_height);
    for (long row = 0; row < rows; row++) memcpy(target + row * frame_width, source + row * stride, frame_width);
  }
  frames_arrived++;
  pthread_mutex_unlock(&frame_lock);
  CVPixelBufferUnlockBaseAddress(pixels, kCVPixelBufferLock_ReadOnly);
}
@end

static SCStream *stream;
static StudioFrameSink *sink;

static SCShareableContent *shareable_content(void) {
  __block SCShareableContent *found = nil;
  dispatch_semaphore_t done = dispatch_semaphore_create(0);
  [SCShareableContent getShareableContentExcludingDesktopWindows:NO onScreenWindowsOnly:YES
                                               completionHandler:^(SCShareableContent *content, NSError *error) {
    found = content;
    dispatch_semaphore_signal(done);
  }];
  dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
  return found;
}

static SCContentFilter *display_filter(SCShareableContent *content, const long *excluded_numbers, long count) {
  NSMutableArray<SCWindow *> *excluded = [NSMutableArray array];
  for (SCWindow *window in content.windows)
    for (long index = 0; index < count; index++)
      if (window.windowID == (CGWindowID)excluded_numbers[index]) [excluded addObject:window];
  return [[SCContentFilter alloc] initWithDisplay:content.displays.firstObject excludingWindows:excluded];
}

long studio_window_number(void *ns_window) {
  return ns_window ? [(__bridge NSWindow *)ns_window windowNumber] : 0;
}

// Lets clicks pass through a window to whatever is under it.
void studio_window_ignore_mouse(void *ns_window) {
  if (ns_window) [(__bridge NSWindow *)ns_window setIgnoresMouseEvents:YES];
}

// Starts capturing the main display at width x height pixels, without
// the windows whose numbers are listed. 0 when running, negative on
// failure.
int studio_capture_start(const long *excluded_numbers, long count, long width, long height, int fps) {
  SCShareableContent *content = shareable_content();
  if (!content || content.displays.count == 0) return -1;

  SCStreamConfiguration *config = [SCStreamConfiguration new];
  config.width = width;
  config.height = height;
  config.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
  config.showsCursor = NO;
  config.minimumFrameInterval = CMTimeMake(1, fps);
  config.queueDepth = 6;

  pthread_mutex_lock(&frame_lock);
  free(latest_frame);
  latest_frame = calloc(1, width * height * 3 / 2);
  frame_width = width;
  frame_height = height;
  frames_arrived = 0;
  pthread_mutex_unlock(&frame_lock);

  sink = [StudioFrameSink new];
  stream = [[SCStream alloc] initWithFilter:display_filter(content, excluded_numbers, count) configuration:config delegate:nil];
  NSError *error = nil;
  dispatch_queue_t queue = dispatch_queue_create("studio.capture", DISPATCH_QUEUE_SERIAL);
  if (![stream addStreamOutput:sink type:SCStreamOutputTypeScreen sampleHandlerQueue:queue error:&error]) return -2;

  __block int result = 0;
  dispatch_semaphore_t started = dispatch_semaphore_create(0);
  [stream startCaptureWithCompletionHandler:^(NSError *startError) {
    result = startError ? -3 : 0;
    dispatch_semaphore_signal(started);
  }];
  dispatch_semaphore_wait(started, DISPATCH_TIME_FOREVER);
  return result;
}

// Copies the newest frame into buffer; returns how many have arrived.
long studio_capture_frame(void *buffer) {
  pthread_mutex_lock(&frame_lock);
  long arrived = frames_arrived;
  if (arrived > 0) memcpy(buffer, latest_frame, frame_width * frame_height * 3 / 2);
  pthread_mutex_unlock(&frame_lock);
  return arrived;
}

void studio_capture_stop(void) {
  if (!stream) return;
  dispatch_semaphore_t stopped = dispatch_semaphore_create(0);
  [stream stopCaptureWithCompletionHandler:^(NSError *error) { dispatch_semaphore_signal(stopped); }];
  dispatch_semaphore_wait(stopped, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC));
  stream = nil;
}

// One BGRA image of the main display (width x height) into buffer.
// 0 on success.
int studio_screenshot(void *buffer, long width, long height) {
  SCShareableContent *content = shareable_content();
  if (!content || content.displays.count == 0) return -1;
  SCStreamConfiguration *config = [SCStreamConfiguration new];
  config.width = width;
  config.height = height;
  config.showsCursor = NO;

  __block CGImageRef image = NULL;
  dispatch_semaphore_t done = dispatch_semaphore_create(0);
  [SCScreenshotManager captureImageWithFilter:display_filter(content, NULL, 0) configuration:config
                            completionHandler:^(CGImageRef captured, NSError *error) {
    if (captured) image = CGImageRetain(captured);
    dispatch_semaphore_signal(done);
  }];
  dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
  if (!image) return -2;

  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(buffer, width, height, 8, width * 4, space,
                                               kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
  CGContextRelease(context);
  CGColorSpaceRelease(space);
  CGImageRelease(image);
  return 0;
}
