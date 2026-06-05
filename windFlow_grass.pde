/*/////////////////////////////////////////////////////////////////////////////
  WIND FLOW: HIGH-FPS TEMPERATURE-BOUND GRADIENT
  Optimized for Pi 5 - Pre-calculated Arrays & Fixed Complexity
  By Damian Vincent Dobrowolski [DVD]
/////////////////////////////////////////////////////////////////////////////*/

float temp, appTemp, windSpeed, windGusts, windDirFrom, windDirTo, relHum, precip, rain, showers, snow, clouds, gustRatio, feelsDiff, rawFeelsDiff, noiseIncr, timeIncrMult, feelsDir, backSway;
String windDirToCard;
PFont customFont;

// --- TUNING KNOBS (The Vibe Controls) ---
int   targetCols = 60;      // Locks the complexity! Pi will always draw 80 columns wide
float vectorWeight = 2.5;   // Line thickness
float lengthMult = 2.0;     // Vector length relative to grid scale
float swayRange = PI/3;     // How far they sway from center

// --- TEMPERATURE COLOR SETTINGS ---
float hueVariance;   // How far colors can drift from the current temperature's base color
float hueSpeed = 3.0;       // Speed of the color pulsing wave
float hueSpread = 0.05;     // Width of the color bands across the screen
float hueSwayMult;   // How much the color shifts when vectors sway
float saturation = 85.0;    // Vibrancy of colors (0-100)
float brightness = 95.0;    // Lightness of colors (0-100)
float opacity = 100.0;      // Line opacity (100 = fastest FPS, lower = liquid blending)

// --- LEGEND & UI SETTINGS ---
boolean showLegend = true;
float legendTextSize = 35.0; // BIGGER TEXT FOR TVs
// ----------------------------------------

PVector[] flowField; 
float[] flowHues; 
int cols, rows, scl;
float zOff = 0;
float procRot = -90;      
float angleOff;      

int fetchInterval = 15 * 60 * 1000; 
int lastFetchTime = 0;

DVDlogo dvd;
ArrayList<Confetti> confettiExplosion = new ArrayList<Confetti>();

// Dynamic UI variables calculated in setup
float legendLineHeightMult = 1.4;
float legendPadding = 25;
float legendScreenMargin = 30;         
color legendBackgroundColor; 
color legendTextColor = color(255);
int legendTargetCorner = 0; 

void setup() {
  noCursor();
  fullScreen(P2D);
  
  scl = width / targetCols;
  
  colorMode(HSB, 360, 100, 100, 100);
  legendBackgroundColor = color(0, 0, 0, 80); 
  
  // Load a cooler, technical monospaced font
  customFont = createFont("Jost-VariableFont_wght.ttf", legendTextSize, true);
  
  
  dvd = new DVDlogo();
  boolean initFetch = fetchWeatherData();
  
  cols = floor((float)width / scl) + 2;
  rows = floor((float)height / scl) + 2;
  
  int totalCells = cols * rows;
  flowField = new PVector[totalCells];
  flowHues = new float[totalCells];
  
  for (int i = 0; i < totalCells; i++) {
    flowField[i] = new PVector();
    flowHues[i] = 0.0;
  }
  
  updateFlowField();
  if (initFetch) printDataSnapshot(); 
  lastFetchTime = millis();
}

void draw() {  
  // hardcode weather vars for testing
  //windSpeed = 20;
  //windGusts = 30;
  //temp = 0;
  //appTemp = -10;
  
  ////////////////////////////////////////////////////////////////////////
  // update dynamic variables
  ////////////////////////////////////////////////////////////////////////
  // If windSpeed is greater than 0, do the math. Otherwise, default to 1.0
  gustRatio = (windSpeed > 0) ? (windGusts / windSpeed) : 1.0;
  rawFeelsDiff = (appTemp - temp);
  feelsDiff = abs(rawFeelsDiff);
  
  // If it feels colder, shift positive (towards 260/Blue). If warmer, shift negative (towards 0/Red).
  if (rawFeelsDiff < 0) {
    feelsDir = 1.0;  
  } else if (rawFeelsDiff > 0) {
    feelsDir = -1.0; 
  } else {
    feelsDir = 0.0;  // Dead accurate, no shift
  }
  
  noiseIncr = map(gustRatio, 1, 2, 0.01, 0.06);     // Spatial noise (Lower = smoother, Higher = more curls)
  timeIncrMult = map(windSpeed, 0, 20, 0, 1.0);   // Overall animation speed
  hueVariance = constrain(map(feelsDiff, 0, 20, 0, 50), 0, 50);
  hueSwayMult = constrain(map(feelsDiff, 0, 20, 0, 50), 0, 50);
  
  // THE EXTREME WEATHER UNLOCK
  // In mild weather, strict 1-way color shifts (0.0). 
  // In extreme cold/heat, smoothly unlocks to allow 2-way shifts (-1.0) for Icy Blues & Fiery Yellows!
  if (appTemp < 0) {
    backSway = constrain(map(appTemp, 0, -20, -0.3, -1.0), -1.0, 0.0);
  } else {
    backSway = 0.0;
  }
  
  // print framerate
  print("\n franerate: " + frameRate + "\n");
  // print dynamic vars
  print("gustRatio: " + gustRatio + "\n noiseIncr: " + noiseIncr + "\n timeIncrMult: " + timeIncrMult + "\n hueVariance: " + hueVariance + "\n hueSwayMult: " + hueSwayMult + "\n");
  
  if (millis() - lastFetchTime >= fetchInterval) {
    if (fetchWeatherData()) printDataSnapshot(); 
    lastFetchTime = millis();
  }
  
  updateFlowField();
  background(0, 0, 0); 
  
  strokeWeight(vectorWeight);
  strokeCap(ROUND); 

  float currentLen = scl * lengthMult;
  
  // 1. CALCULATE TEMPERATURE BASE HUE
  // Map temperatures to color wheel: 10F = 260 (Purple/Blue), 100F = 0 (Red)
  float baseHue = constrain(map(temp, -10, 100, 260, 0), 0, 260);

  for (int y = -1; y < rows; y++) {
    for (int x = -1; x < cols; x++) {
      int safeX = constrain(x, 0, cols - 1);
      int safeY = constrain(y, 0, rows - 1);
      int index = safeX + safeY * cols;
      
      PVector v = flowField[index];
      float px = x * scl;
      float py = y * scl;
      
      // TEMPERATURE-BOUND PULSE MATH
      float rawWave = sin((x + y) * hueSpread + zOff * hueSpeed);
      
      // Map the sine wave using the backSway unlock!
      float directionalWave = map(rawWave, -1, 1, backSway, 1);
      
      // Multiply the shift by our positive/negative tempDirection!
      float colorShift = directionalWave * hueVariance * feelsDir;
      float swayHue = flowHues[index]; 
      
      // Calculate the raw hue without wrapping
      float rawHue = baseHue + colorShift + swayHue;
      
      // THE FIX: Build a wall at 0 (Red) so it cannot wrap backward into Purple (359).
      // We set the upper limit to 280 to give the coldest days (260) room to pulse.
      float finalHue = constrain(rawHue, 0, 280);
      
      stroke(finalHue, saturation, brightness, opacity); 
      line(px, py, px + v.x * currentLen, py + v.y * currentLen);
    }
  } 
  
  for (int i = confettiExplosion.size()-1; i >= 0; i--) {
    Confetti c = confettiExplosion.get(i);
    c.update();
    c.display();
    if (c.isDead()) confettiExplosion.remove(i);
  }
  
  dvd.update();   
  dvd.display();
  
  if (showLegend) {
    drawLegend();
    drawSignature();
  }
}

void updateFlowField() {
  float yOff = 0;
  for (int y = 0; y < rows; y++) {
    float xOff = 0;
    for (int x = 0; x < cols; x++) {
      int index = x + y * cols;
      if (index >= flowField.length) continue;
      
      float noiseVal = noise(xOff, yOff, zOff);
      
      float swayAngle = map(noiseVal, 0, 1, -swayRange, swayRange); 
      float finalAngle = angleOff + swayAngle;
      flowField[index].set(cos(finalAngle), sin(finalAngle));
      
      // Allow the individual wind ribbons to sway backward if extreme weather is unlocked!
      float noiseShift = map(noiseVal, 0.2, 0.8, backSway * hueSwayMult, hueSwayMult);
      noiseShift = constrain(noiseShift, backSway * hueSwayMult, hueSwayMult);
      
      // Apply the direction!
      flowHues[index] = noiseShift * feelsDir;
      
      xOff += noiseIncr;
    }
    yOff += noiseIncr; 
  }
  
  float smoothSpeed = map(windSpeed, 0, 30, 0.002, 0.015) * timeIncrMult;
  zOff += smoothSpeed; 
}

// --- UTILITIES ---

void triggerConfetti(float x, float y) {
  // MORE GRAND: 300 pieces instead of 100
  for (int i = 0; i < 300; i++) {
    confettiExplosion.add(new Confetti(x, y));
  }
}

class Confetti {
  PVector pos, vel;
  float gravity = 0.015; // SLOWER: Float gently like feathers
  color c;
  float lifespan = 255;  // Start fully opaque
  float size;
  float rot, rotSpeed;
  
  Confetti(float x, float y) {
    pos = new PVector(x, y);
    // Explode outward further, but float down slower
    vel = PVector.random2D().mult(random(2, 7));
    vel.y -= random(2, 5); // Give an initial upward burst
    c = color(random(360), 80, 95);
    size = random(8, 18); // BIGGER confetti pieces
    rot = random(TWO_PI);
    rotSpeed = random(-0.1, 0.1);
  }
  
  void update() { 
    vel.y += gravity; 
    pos.add(vel); 
    lifespan -= 0.8; // Fades out much slower
    rot += rotSpeed;
  }
  
  void display() { 
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(rot);
    fill(c, lifespan); 
    noStroke(); 
    rectMode(CENTER);
    rect(0, 0, size, size * 0.6); // Rectangles look more like real confetti than squares
    rectMode(CORNER);
    popMatrix();
  }
  
  boolean isDead() { return (lifespan < 0); }
}

void drawLegend() {
  textFont(customFont);
  textSize(legendTextSize);
  float calculatedLineHeight = legendTextSize * legendLineHeightMult;
  String[] labels = {"Wind speed: ", "Wind gusts: ", "Direction: ", "Temp: ", "Feels: "};
  String[] values = {round(windSpeed)+" mph", round(windGusts)+" mph", windDirToCard+" ("+round(windDirTo)+"º)", round(temp)+" ºF", round(appTemp)+" ºF"};
  
  float maxLineWidth = 0;
  for (int i = 0; i < labels.length; i++) {
    float currentLineWidth = textWidth(labels[i]) + textWidth(values[i]);
    if (currentLineWidth > maxLineWidth) maxLineWidth = currentLineWidth;
  }
  
  float legendBoxW = maxLineWidth + (2 * legendPadding);
  float legendBoxH = ((labels.length - 1) * calculatedLineHeight) + legendTextSize + (2 * legendPadding);
  
  float lx = 0, ly = 0;
  switch (legendTargetCorner) {
    case 0: lx = width - legendBoxW - legendScreenMargin; ly = legendScreenMargin; break;
    case 1: lx = width - legendBoxW - legendScreenMargin; ly = height - legendBoxH - legendScreenMargin; break;
    case 2: lx = legendScreenMargin; ly = height - legendBoxH - legendScreenMargin; break;
    case 3: lx = legendScreenMargin; ly = legendScreenMargin; break;
  }
  
  fill(legendBackgroundColor);
  noStroke();
  rect(lx, ly, legendBoxW, legendBoxH);
  
  textAlign(LEFT, TOP);
  float drawX = lx + legendPadding;
  float drawY = ly + legendPadding;
  
  for (int i = 0; i < labels.length; i++) {
    fill(0, 0, 100, 60); // White-ish at 60% opacity
    text(labels[i], drawX, drawY);
    fill(0, 0, 100);     // Solid White
    text(values[i], drawX + textWidth(labels[i]), drawY);
    drawY += calculatedLineHeight;
  }
}

void drawSignature() {
  textFont(customFont); // Apply the cool font here too
  float sigTextSize = legendTextSize * 0.6;
  textSize(sigTextSize);
  
  String signature = "by Damian Vincent Dobrowolski [DVD]";
  float sigWidth = textWidth(signature);
  
  float paddingX = 15;
  float paddingY = 10;
  float boxW = sigWidth + (paddingX * 2);
  float boxH = sigTextSize + (paddingY * 2);
  
  // ALWAYS BOTTOM
  float boxY = height - boxH - legendScreenMargin;
  float boxX;
  
  // COLLISION AVOIDANCE LOGIC:
  // If Legend is on the RIGHT side of the screen (Corner 0 or 1)
  if (legendTargetCorner == 0 || legendTargetCorner == 1) {
    // Signature moves to Bottom-LEFT
    boxX = legendScreenMargin; 
  } else {
    // If Legend is on the LEFT side of the screen (Corner 2 or 3)
    // Signature moves to Bottom-RIGHT
    boxX = width - boxW - legendScreenMargin; 
  }
  
  fill(0, 0, 0); 
  noStroke();
  rect(boxX, boxY, boxW, boxH);
  
  textAlign(LEFT, TOP); 
  fill(0, 0, 100); 
  text(signature, boxX + paddingX, boxY + paddingY - (sigTextSize * 0.1) + 3);
}

String degreesToCard(float degrees) {
  String[] directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"};
  return directions[round(degrees / 45.0f) % 8];
}

void printDataSnapshot() {
  println("--- API Snapshot: " + nf(hour(), 2) + ":" + nf(minute(), 2) + " ---");
}
