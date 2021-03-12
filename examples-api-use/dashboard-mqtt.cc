// -*- mode: c++; c-basic-offset: 2; indent-tabs-mode: nil; -*-
// Custom version of clock, but with custom content below it, 
// and tailored towards a 128x64 (64x64 chained 1) display


#include "led-matrix.h"
#include "graphics.h"
#include "MQTTClient.h"

#include <assert.h>
#include <getopt.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <deque>
#include <string>
#include <vector>

#define ADDRESS     "tcp://klaverstraat11.local:1883"
#define CLIENTID    "Dashboard"
#define QOS         1
#define TIMEOUT     10000L

using namespace rgb_matrix;

const std::string topic_dashboard_message("DashboardFeed/msg");
const std::string topic_dashboard_branches("DashboardFeed/branch");
const Color color_red(255, 0, 0);
const Color color_green(0, 255, 0);
const Color color_orange(255, 170, 0);
const Color color_black(0, 0, 0);
const std::string status_color_red("red");
const std::string status_color_green("green");
const std::string status_color_orange("orange");

std::string message_line;
std::deque<std::string> branch_names(3, std::string(""));
std::deque<Color> branch_colors(3, color_black);

volatile bool interrupt_received = false;
static void InterruptHandler(int signo) {
  interrupt_received = true;
}

void delivered(void *context, MQTTClient_deliveryToken dt)
{
    printf("Message with token value %d delivery confirmed\n", dt);
}

int msgarrvd(void *context, char *topicName, int topicLen, MQTTClient_message *message)
{
    int i;
    char* payloadptr;
    int payloadlen = message->payloadlen;
    char line_buffer[payloadlen];
    // TODO remove debug printing
    //printf("Message arrived\n");
    //printf("     topic: %s\n", topicName);
    //printf("      size: %d\n", payloadlen);
    //printf("   message: ");
    payloadptr = (char*)message->payload;
    for(i=0; i<payloadlen; i++)
    {
        line_buffer[i] = payloadptr[i];
        // putchar(payloadptr[i]);
    }
    // putchar('\n');
    
    std::string line(line_buffer, (size_t)payloadlen);
    std::string topic(topicName);

    if (topic.compare(0, topic_dashboard_message.length(), topic_dashboard_message) == 0) {
      //printf("Message received: %s\n", line.c_str());
      message_line = line;
    } else if (topic.compare(0, topic_dashboard_branches.length(), topic_dashboard_branches) == 0) {
      //printf("Branch status update");
      std::string index_str = topic.substr(topic_dashboard_branches.length()+1, 1);
      int index = atoi(index_str.c_str());
      //printf("Working for branch index %d\n", index);
      if (topic.find(std::string("name")) != std::string::npos) {
        branch_names[index] = line;
      } else if (topic.find(std::string("status")) != std::string::npos) {
        // Parsing the color from the payload
        if (line.find(status_color_red) != std::string::npos) {
          branch_colors[index] = color_red;
        } else if (line.find(status_color_green) != std::string::npos) {
          branch_colors[index] = color_green;
        } else if (line.find(status_color_orange) != std::string::npos) {
          branch_colors[index] = color_orange;
        } else {
          branch_colors[index] = color_black;
        }
      }
    }

    MQTTClient_freeMessage(&message);
    MQTTClient_free(topicName);
    return 1;
}

void connlost(void *context, char *cause)
{
    printf("\nConnection lost\n");
    printf("     cause: %s\n", cause);
    // TODO - wire retry connect?
}

int main(int argc, char *argv[]) {
  RGBMatrix::Options matrix_options;
  rgb_matrix::RuntimeOptions runtime_opt;
  runtime_opt.daemon = 0;
  runtime_opt.gpio_slowdown = 4;
  runtime_opt.drop_privileges = 1;
  runtime_opt.do_gpio_init = true;

  matrix_options.brightness = 50;
  matrix_options.rows = 64;
  matrix_options.cols = 64;
  matrix_options.chain_length = 2;

  std::vector<std::string> format_lines;
  Color color(120, 150, 255);
  Color message_color(255, 255, 255);
  Color bg_color(0, 0, 0);

  int clock_offset_x = 41;
  int clock_offset_y = 0;
  int letter_spacing = 0;
  int line_spacing = 0;
  int message_offset_x = 2;
  int message_offset_y = 0;
  int branch_offset_x = 14;
  int branch_offset_y = 0;

  format_lines.push_back("%H:%M:%S");

  /*
   * Load font. This needs to be a filename with a bdf bitmap font.
   */
  rgb_matrix::Font font;
  if (!font.LoadFont("/home/pi/led-matrix/rpi-rgb-led-matrix/fonts/helvR12.bdf")) {
    fprintf(stderr, "Couldn't load font\n");
    return 1;
  }

  RGBMatrix *matrix = RGBMatrix::CreateFromOptions(matrix_options, runtime_opt);
  if (matrix == NULL)
    return 1;

  FrameCanvas *offscreen = matrix->CreateFrameCanvas();

  char text_buffer[256];
  struct timespec next_time;
  next_time.tv_sec = time(NULL);
  next_time.tv_nsec = 0;
  struct tm tm;

  MQTTClient client;
  MQTTClient_connectOptions conn_opts = MQTTClient_connectOptions_initializer;
  int rc;
  MQTTClient_create(&client, ADDRESS, CLIENTID,
      MQTTCLIENT_PERSISTENCE_NONE, NULL);
  conn_opts.keepAliveInterval = 20;
  conn_opts.cleansession = 1;
  MQTTClient_setCallbacks(client, NULL, connlost, msgarrvd, delivered);
  if ((rc = MQTTClient_connect(client, &conn_opts)) != MQTTCLIENT_SUCCESS)
  {
      printf("Failed to connect, return code %d\n", rc);
      exit(EXIT_FAILURE);
  }
  printf("Subscribing to topics for client %s using QoS %d\n\n", CLIENTID, QOS);
  MQTTClient_subscribe(client, "DashboardFeed/#", QOS);

  signal(SIGTERM, InterruptHandler);
  signal(SIGINT, InterruptHandler);
  
  while (!interrupt_received) {
    offscreen->Fill(bg_color.r, bg_color.g, bg_color.b);
    localtime_r(&next_time.tv_sec, &tm);

    int line_offset = 0;
    // Showing Clock
    for (const std::string &line : format_lines) {
      strftime(text_buffer, sizeof(text_buffer), line.c_str(), &tm);
      rgb_matrix::DrawText(offscreen, font,
                           clock_offset_x, clock_offset_y + font.baseline() + line_offset,
                           color, NULL, text_buffer,
                           letter_spacing);
      line_offset += font.height() + line_spacing;
    }

    // Showing message
    if (!message_line.empty()) {
      rgb_matrix::DrawText(offscreen, font,
                           message_offset_x, message_offset_y + font.baseline() + line_offset,
                           message_color, NULL, message_line.c_str(),
                           letter_spacing);
      line_offset += font.height() + line_spacing;
    }

    // Showing branch status
    for (int i = 0; i < 3; i++) {
      rgb_matrix::DrawCircle(offscreen, 7, 7 + line_offset, 5, branch_colors[i]);
      rgb_matrix::DrawCircle(offscreen, 7, 7 + line_offset, 4, branch_colors[i]);
      rgb_matrix::DrawCircle(offscreen, 7, 7 + line_offset, 3, branch_colors[i]);
      rgb_matrix::DrawCircle(offscreen, 7, 7 + line_offset, 2, branch_colors[i]);
      rgb_matrix::DrawCircle(offscreen, 7, 7 + line_offset, 1, branch_colors[i]);
      rgb_matrix::DrawText(offscreen, font,
                           branch_offset_x, branch_offset_y + font.baseline() + line_offset,
                           message_color, NULL, branch_names[i].c_str(),
                           letter_spacing);
      line_offset += font.height() + line_spacing;
    }

    // Wait until we're ready to show it.
    clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &next_time, NULL);

    // Atomic swap with double buffer
    offscreen = matrix->SwapOnVSync(offscreen);

    next_time.tv_sec += 1;
  }

  MQTTClient_disconnect(client, 10000);
  MQTTClient_destroy(&client);

  // Finished. Shut down the RGB matrix.
  delete matrix;

  write(STDOUT_FILENO, "\n", 1);  // Create a fresh new line after ^C on screen
  return 0;
}
