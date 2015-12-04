/* 
 Batch pixel sorting of images.
 
 TO DO______
 • Live input mode where sorting parameters are controlled through MIDI input
 • Use shaders instead
 • Make operations state-based rather than stateless
 • Audio-Reactive (Max/MSP?)
 • Alter Image should work the same irrespective of image dimensions
 */

import processing.pdf.*;
import themidibus.*;
import processing.video.*;

Movie myMovie;
MidiBus myBus;
PShader shader;

PImage img;

int loops = 1;

int width = 1280;
int height = 720;

// Path of unedited frames
String[] frames;

// Live Parameters
int threshold = 60;
int density = 1;
int mode = 0;

int[] offset = {int(random(500000, 50000)), int(random(200000, 200000))};

boolean saved = false;

// PIXEL SORTING SECTION
int maxIterations = 2000;               // max # of times to go through the image
int dist = 200;                         // maximum distance downward to travel
int margin = 50;                        // margin of error for finding the next seed pixel
boolean saveIt = true;                  // save the output to high-res file?

// set global variables for efficiency - avoids allocating them each pixel
int pos, x, y;                          // location variables, set in code below
float r, g, b, tr, tb, tg;              // color variables for comparing new seed positions
color t;                                // temp color to compare pixels in image
int[] traversed = new int[0];           // array to store pixels we've already traversed (avoids duplicates)
// =====================


void setup() {
  size(1280, 720, P3D);
  //beginRecord(PDF, "my_output_" + str(random(10000)) + ".pdf");
  //img = alterImage("frames/img229.png");
  //imageMode(CORNERS);
  //image(img, 0, 0, img.width, img.height);
  //endRecord();

  // MIDI STUFF ==================
  //MidiBus.list();
  myBus = new MidiBus(this, 0, 0);
  shader = loadShader("pixelate.glsl");
  //myMovie = new Movie(this, "footage.mp4");
  //myMovie.loop();

  frames = listFileNames(sketchPath() + "/data/frames/");

  //int cnt = 0;
  //for (String frame : frames) {
  //  if (cnt > 2) {
  //    break;
  //  }
  //  img = loadImage("frames/" + frame);

  //  img = alterImage(img);
  //img = simpleSort(img);
  // img = sortImage("frames/" + frame);

  //width = img.width;
  //height = img.height;

  //imageMode(CORNERS);
  //image(img, 0, 0, img.width, img.height);
  //saveFrame("editedFrames/" + frame);
  //cnt++;
  //}

  //noLoop();
}

void draw() {
  // MIDI STUFF =============================
  int channel = 0;
  int pitch = 64;
  int velocity = 127;
  int number = 0;
  int value = 90;
  //myBus.sendNoteOn(channel, pitch, velocity); // Send a Midi noteOn
  //delay(200);
  //myBus.sendNoteOff(channel, pitch, velocity); // Send a Midi nodeOff
  myBus.sendControllerChange(channel, number, value); // Send a controllerChange
  //midiDelay(2000);
  // ========================================



  // Loop between unedited frames
  int currentFrame = frameCount % frames.length;
  String frame = frames[currentFrame];

  img = loadImage("frames/" + frame);
  
  // Using shaders
  //shader.set("step", 1.0/float(width), 1.0/float(height));
  //shader.set("srcTex", myMovie);
  //shader(shader);
  //rect(0, 0, width, height);
  
  img = simpleSort(img, threshold, density, mode);

  imageMode(CORNERS);
  image(img, 0, 0, img.width, img.height);
  //saveFrame("editedFrames/" + frame);
}

void keyPressed() {
  if (key == 'q') {
    endRecord();
    exit();
  }
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}

// MIDI STUFF ============================
void midiDelay(int time) {
  int current = millis();
  while (millis() < current+time) {
    Thread.yield();
  }
}

void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
}

void noteOff(int channel, int pitch, int velocity) {
  // Receive a noteOff
  println();
  println("Note Off:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
}

void controllerChange(int channel, int number, int value) {
  // Receive a controllerChange
  println();
  println("Controller Change:");
  println("--------");
  println("Channel:"+channel);
  println("Number:"+number);
  println("Value:"+value);

  // Number 16 and 17 will be controlling threshold and density respectively
  if (number == 17) {
    threshold = int(map(value, 0, 127, 0, 100));
    println("Outer threshold is: " + threshold);
  }

  // Numbers 32, 33, and 34 will be controlling modes 0, 1, 2 respectively
  if (number == 32 || number == 33 || number == 34) {
    mode = (number-2)%3;
    println("Mode is: " + mode);
  }
}
// ====================================

PImage alterImage(PImage img) {
  //img = loadImage(imgName);

  println(img.width, img.height);
  frameRate(24);

  int[] offset = {int(random(500000, 500050)), int(random(200000, 200005))};

  for (int j = 0; j < 2; j++) {
    img.loadPixels();
    for (int i = 0; i < img.width*img.height; i++) {
      color c = img.pixels[i];
      if (i%3 == 0) {
        // Get pixel data of neighboring pixel
        color n_c = img.pixels[(i+height)%(img.width*img.height-1)];
        img.pixels[(i+offset[0])%(img.width*img.height-1)] = color(green(n_c), blue(c), red(n_c), 255);
      } else {
        if (i < 5) {
          continue;
        }
        // Get pixel data of neighboring pixel
        color n_c = img.pixels[i-5];
        img.pixels[(i+1000000000)%(img.width*img.height-1)] = color(blue(n_c), green(n_c), red(n_c), 255);
      }
    }
    img.updatePixels();
  }

  return img;
}

String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } else {
    return null;
  }
}

// PIXEL SORTING SECTION ======================================
PImage simpleSort(PImage img, int... params) {
  // 60, 1, 0
  int threshold = params.length > 0 ? params[0] : 60;
  int density = params.length > 1 ? params[1] : 1;
  int mode = params.length > 2 ? params[2] : 0;

  //PImage img = loadImage(filename);
  for (int w=0; w<img.width*img.height; w++) {
    if ((img.pixels[w]%density) == 0) {
      img.loadPixels();
      switch(mode) {
      case 0:
        if (w > img.width) {
          if (brightness(img.pixels[w]) > threshold) {
            //img.pixels[w] = img.pixels[w-img.width];
            img.pixels[w] = img.pixels[w] << img.pixels[w-img.width];
          }
        }
        break;
      case 1:
        if (w > 0) {
          if (brightness(img.pixels[w]) > threshold) {
            img.pixels[w] = img.pixels[w-1];
          }
        }
        break;
      case 2:
        if (w > img.width) {
          if (brightness(img.pixels[w]) > threshold) {
            img.pixels[w-img.width] = int(abs(sin(w)*w));
          }
        }
        break;
      }

      img.updatePixels();
    }
  }
  return img;
}