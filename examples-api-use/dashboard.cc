// -*- mode: c++; c-basic-offset: 2; indent-tabs-mode: nil; -*-
// Custom version of clock, but with custom content below it, 
// and tailored towards a 128x64 (64x64 chained 1) display


#include "led-matrix.h"
#include "graphics.h"

#include <assert.h>
#include <getopt.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <vector>
#include <string>

using namespace rgb_matrix;

volatile bool interrupt_received = false;
static void InterruptHandler(int signo) {
  interrupt_received = true;
}

struct Pixel {
  Pixel() : red(0), green(0), blue(0){}
  uint8_t red;
  uint8_t green;
  uint8_t blue;
};

struct Image {
  Image() : width(-1), height(-1), image(NULL) {}
  ~Image() { Delete(); }
  void Delete() { delete [] image; Reset(); }
  void Reset() { image = NULL; width = -1; height = -1; }
  inline bool IsValid() { return image && height > 0 && width > 0; }
  const Pixel &getPixel(int x, int y) {
    static Pixel black;
    if (x < 0 || x >= width || y < 0 || y >= height) return black;
    return image[x + width * y];
  }

  int width;
  int height;
  Pixel *image;
};

// Read line, skip comments.
char *ReadLine(FILE *f, char *buffer, size_t len) {
  char *result;
  do {
    result = fgets(buffer, len, f);
  } while (result != NULL && result[0] == '#');
  return result;
}

// Current image is only manipulated in our thread.
Image current_image_;

// New image can be loaded from another thread, then taken over in main thread
Mutex mutex_new_image_;
Image new_image_;

int32_t horizontal_position_;

// _very_ simplified. Can only read binary P6 PPM. Expects newlines in headers
// Not really robust. Use at your own risk :)
// This allows reload of an image while things are running, e.g. you can
// live-update the content.
bool LoadPPM(const char *filename) {
  FILE *f = fopen(filename, "r");
  // check if file exists
  if (f == NULL && access(filename, F_OK) == -1) {
    fprintf(stderr, "File \"%s\" doesn't exist\n", filename);
    return false;
  }
  if (f == NULL) return false;
  char header_buf[256];
  const char *line = ReadLine(f, header_buf, sizeof(header_buf));
#define EXIT_WITH_MSG(m) { fprintf(stderr, "%s: %s |%s", filename, m, line); \
    fclose(f); return false; }
  if (sscanf(line, "P6 ") == EOF)
    EXIT_WITH_MSG("Can only handle P6 as PPM type.");
  line = ReadLine(f, header_buf, sizeof(header_buf));
  int new_width, new_height;
  if (!line || sscanf(line, "%d %d ", &new_width, &new_height) != 2)
    EXIT_WITH_MSG("Width/height expected");
  int value;
  line = ReadLine(f, header_buf, sizeof(header_buf));
  if (!line || sscanf(line, "%d ", &value) != 1 || value != 255)
    EXIT_WITH_MSG("Only 255 for maxval allowed.");
  const size_t pixel_count = new_width * new_height;
  Pixel *new_image = new Pixel [ pixel_count ];
  assert(sizeof(Pixel) == 3);   // we make that assumption.
  if (fread(new_image, sizeof(Pixel), pixel_count, f) != pixel_count) {
    line = "";
    EXIT_WITH_MSG("Not enough pixels read.");
  }
#undef EXIT_WITH_MSG
  fclose(f);
  fprintf(stderr, "Read image '%s' with %dx%d\n", filename,
          new_width, new_height);
  horizontal_position_ = 0;
  MutexLock l(&mutex_new_image_);
  new_image_.Delete();  // in case we reload faster than is picked up
  new_image_.image = new_image;
  new_image_.width = new_width;
  new_image_.height = new_height;
  return true;
}

int main(int argc, char *argv[]) {
  RGBMatrix::Options matrix_options;
  rgb_matrix::RuntimeOptions runtime_opt;
  runtime_opt.daemon = 0;
  runtime_opt.gpio_slowdown = 0;
  runtime_opt.drop_privileges = 1;
  runtime_opt.do_gpio_init = true;

  matrix_options.brightness = 50;
  matrix_options.rows = 64;
  matrix_options.cols = 64;
  matrix_options.chain_length = 2;

  std::vector<std::string> format_lines;
  Color color(120, 150, 255);
  Color bg_color(0, 0, 0);

  int x_orig = 41;
  int y_orig = 0;
  int letter_spacing = 0;
  int line_spacing = 0;

  format_lines.push_back("%H:%M:%S");

  /*
   * Load font. This needs to be a filename with a bdf bitmap font.
   */
  rgb_matrix::Font font;
  if (!font.LoadFont("/home/pi/led-matrix/rpi-rgb-led-matrix/fonts/helvR12.bdf")) {
    fprintf(stderr, "Couldn't load font\n");
    return 1;
  }

  if (!LoadPPM("/home/pi/led-matrix/rpi-rgb-led-matrix/examples-api-use/runtext.ppm")) {
    fprintf(stderr, "Couldn't load PPM image\n");
    return 1;
  }

  RGBMatrix *matrix = RGBMatrix::CreateFromOptions(matrix_options, runtime_opt);
  if (matrix == NULL)
    return 1;

  const int x = x_orig;
  int y = y_orig;

  FrameCanvas *offscreen = matrix->CreateFrameCanvas();

  char text_buffer[256];
  struct timespec next_time;
  next_time.tv_sec = time(NULL);
  next_time.tv_nsec = 0;
  struct tm tm;

  signal(SIGTERM, InterruptHandler);
  signal(SIGINT, InterruptHandler);

  const int screen_height = offscreen->height();
  const int screen_width = offscreen->width();
    
  while (!interrupt_received) {
    offscreen->Fill(bg_color.r, bg_color.g, bg_color.b);
    localtime_r(&next_time.tv_sec, &tm);

    int line_offset = 0;
    for (const std::string &line : format_lines) {
      strftime(text_buffer, sizeof(text_buffer), line.c_str(), &tm);
      rgb_matrix::DrawText(offscreen, font,
                           x, y + font.baseline() + line_offset,
                           color, NULL, text_buffer,
                           letter_spacing);
      line_offset += font.height() + line_spacing;
    }

    {
      MutexLock l(&mutex_new_image_);
      if (new_image_.IsValid()) {
        current_image_.Delete();
        current_image_ = new_image_;
        new_image_.Reset();
      }
    }
    if (!current_image_.IsValid()) {
      usleep(100 * 1000);
      continue;
    }
    for (int x = 0; x < screen_width; ++x) {
      for (int y = 0; y < screen_height; ++y) {
        const Pixel &p = current_image_.getPixel(x, y);
        offscreen->SetPixel(x, y + line_offset, p.red, p.green, p.blue);
      }
    }
    //offscreen = matrix->SwapOnVSync(offscreen);
    // No scrolling. We don't need the image anymore.
    //current_image_.Delete();

    // Wait until we're ready to show it.
    clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &next_time, NULL);

    // Atomic swap with double buffer
    offscreen = matrix->SwapOnVSync(offscreen);

    next_time.tv_sec += 1;
  }

  current_image_.Delete();

  // Finished. Shut down the RGB matrix.
  delete matrix;

  write(STDOUT_FILENO, "\n", 1);  // Create a fresh new line after ^C on screen
  return 0;
}
