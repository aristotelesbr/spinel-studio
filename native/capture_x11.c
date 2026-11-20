// Screen capture through X11, exposed as the same plain C functions as
// native/capture.m (spinel_studio/platform/linux/screen_capture.rb).
//
// A thread keeps the newest frame of the root window in NV12. X11 gives
// the screen without the cursor, as the macOS capture is asked to, and
// cannot leave a window out, so the excluded windows are ignored.
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/Xfixes.h>
#include <X11/extensions/shape.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static pthread_mutex_t frame_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_t capture_thread;
static uint8_t *latest_frame;
static long frame_width, frame_height, frames_arrived;
static int frame_rate;
static volatile bool capturing;
static Display *keys_display;

// BGRA rows (stride bytes apart) into NV12, BT.601 video range, which is
// how ffmpeg reads raw frames that carry no color tags.
static void bgra_to_nv12(const uint8_t *bgra, long stride, uint8_t *nv12, long width, long height) {
  uint8_t *luma = nv12, *chroma = nv12 + width * height;
  for (long y = 0; y < height; y++) {
    const uint8_t *row = bgra + y * stride;
    for (long x = 0; x < width; x++) {
      int b = row[x * 4], g = row[x * 4 + 1], r = row[x * 4 + 2];
      luma[y * width + x] = (uint8_t)((66 * r + 129 * g + 25 * b + 128) / 256 + 16);
      if ((y & 1) == 0 && (x & 1) == 0) {
        uint8_t *pair = chroma + (y / 2) * width + x;
        pair[0] = (uint8_t)((-38 * r - 74 * g + 112 * b + 128) / 256 + 128);
        pair[1] = (uint8_t)((112 * r - 94 * g - 18 * b + 128) / 256 + 128);
      }
    }
  }
}

// The root window's pixels (width x height, clipped to the screen), or
// NULL. The caller destroys the image.
static XImage *grab(Display *display, long width, long height) {
  Window root = DefaultRootWindow(display);
  XWindowAttributes screen;
  XGetWindowAttributes(display, root, &screen);
  if (width > screen.width) width = screen.width;
  if (height > screen.height) height = screen.height;
  return XGetImage(display, root, 0, 0, width, height, AllPlanes, ZPixmap);
}

static void *capture_loop(void *unused) {
  Display *display = XOpenDisplay(NULL);
  if (!display) return NULL;
  uint8_t *frame = calloc(1, frame_width * frame_height * 3 / 2);
  struct timespec pause = { 0, 1000000000L / frame_rate };
  while (capturing) {
    XImage *image = grab(display, frame_width, frame_height);
    if (image) {
      bgra_to_nv12((const uint8_t *)image->data, image->bytes_per_line, frame, image->width & ~1, image->height & ~1);
      XDestroyImage(image);
      pthread_mutex_lock(&frame_lock);
      memcpy(latest_frame, frame, frame_width * frame_height * 3 / 2);
      frames_arrived++;
      pthread_mutex_unlock(&frame_lock);
    }
    nanosleep(&pause, NULL);
  }
  free(frame);
  XCloseDisplay(display);
  return NULL;
}

// Lets clicks pass through a window to whatever is under it: its input
// shape becomes empty.
void studio_window_ignore_mouse(long window) {
  Display *display = XOpenDisplay(NULL);
  if (!display || !window) return;
  XserverRegion nothing = XFixesCreateRegion(display, NULL, 0);
  XFixesSetWindowShapeRegion(display, (Window)window, ShapeInput, 0, 0, nothing);
  XFixesDestroyRegion(display, nothing);
  XCloseDisplay(display);
}

// Starts capturing the screen at width x height pixels. 0 when running,
// negative on failure.
int studio_capture_start(const long *excluded_numbers, long count, long width, long height, int fps) {
  Display *display = XOpenDisplay(NULL);
  if (!display) return -1;
  XCloseDisplay(display);
  pthread_mutex_lock(&frame_lock);
  free(latest_frame);
  latest_frame = calloc(1, width * height * 3 / 2);
  frame_width = width;
  frame_height = height;
  frame_rate = fps > 0 ? fps : 30;
  frames_arrived = 0;
  pthread_mutex_unlock(&frame_lock);
  capturing = true;
  if (pthread_create(&capture_thread, NULL, capture_loop, NULL) != 0) {
    capturing = false;
    return -2;
  }
  return 0;
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
  if (!capturing) return;
  capturing = false;
  pthread_join(capture_thread, NULL);
}

// One BGRA image of the screen (width x height) into buffer. 0 on
// success.
int studio_screenshot(void *buffer, long width, long height) {
  Display *display = XOpenDisplay(NULL);
  if (!display) return -1;
  XImage *image = grab(display, width, height);
  if (!image) {
    XCloseDisplay(display);
    return -2;
  }
  uint32_t *out = buffer;
  for (long y = 0; y < image->height; y++) {
    const uint32_t *row = (const uint32_t *)(image->data + y * image->bytes_per_line);
    for (long x = 0; x < image->width; x++) out[y * width + x] = row[x] | 0xFF000000u;
  }
  XDestroyImage(image);
  XCloseDisplay(display);
  return 0;
}

// Where the pointer is on the screen, into x and y; returns whether the
// left button is held.
bool studio_pointer(int *x, int *y) {
  if (!keys_display) keys_display = XOpenDisplay(NULL);
  if (!keys_display) return false;
  Window root, child;
  int window_x, window_y;
  unsigned int buttons = 0;
  XQueryPointer(keys_display, DefaultRootWindow(keys_display), &root, &child, x, y, &window_x, &window_y, &buttons);
  return (buttons & Button1Mask) != 0;
}

// Whether the key of an X11 keysym is held, anywhere on screen.
bool studio_key_down(long keysym) {
  if (!keys_display) keys_display = XOpenDisplay(NULL);
  if (!keys_display) return false;
  KeyCode code = XKeysymToKeycode(keys_display, (KeySym)keysym);
  if (!code) return false;
  char keys[32];
  XQueryKeymap(keys_display, keys);
  return (keys[code / 8] >> (code % 8)) & 1;
}
