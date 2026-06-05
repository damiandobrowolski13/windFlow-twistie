class DVDlogo {
  PVector pos;
  PVector vel;
  String logoText = "DVD";
  float logoSize = 50;
  float w, h;
  color currentTint;
  
  // --- TRAIL SETTINGS ---
  int trailLength = 25; // How long the echo trail is
  PVector[] history;    // Array to remember past positions

  DVDlogo() {
    pos = new PVector(width / 2, height / 2);
    vel = PVector.random2D();
    
    textSize(logoSize);
    w = textWidth(logoText);
    h = textAscent();
    
    // Initialize the history array with the starting position
    history = new PVector[trailLength];
    for (int i = 0; i < trailLength; i++) {
      history[i] = new PVector(pos.x, pos.y);
    }
    
    changeColor();
  }

  void update() {
    // 1. Shift all historical positions down the line
    for (int i = trailLength - 1; i > 0; i--) {
      history[i].x = history[i-1].x;
      history[i].y = history[i-1].y;
    }
    // 2. Save the newest position at the front of the array
    history[0].x = pos.x;
    history[0].y = pos.y;

    pos.add(vel);
    checkBounce();
  }

  void checkBounce() {
    float margin = 10.0; 
    boolean hitX = false;
    boolean hitY = false;

    if (pos.x <= 0 || pos.x + w >= width) {
      vel.x *= -1;
      hitX = true;
      changeColor();
    }
    if (pos.y - h <= 0 || pos.y >= height) {
      vel.y *= -1;
      hitY = true;
      changeColor();
    }

    if (hitX && (pos.y - h <= margin || pos.y >= height - margin)) {
       triggerConfetti(pos.x + w/2, pos.y - h/2);
    } else if (hitY && (pos.x <= margin || pos.x + w >= width - margin)) {
       triggerConfetti(pos.x + w/2, pos.y - h/2);
    }
  }

  void display() {
    textAlign(LEFT, TOP);

    // Draw the fading echo trail backwards (so the tail renders underneath)
    for (int i = trailLength - 1; i >= 0; i--) {
      // Map the alpha to fade from 60 (near the logo) down to 0 (the tail)
      float alpha = map(i, 0, trailLength, 60, 0); 
      
      // The fill command accepts (Color, Alpha) automatically!
      fill(currentTint, alpha);
      textSize(logoSize);
      text(logoText, history[i].x, history[i].y - h);
    }

    // Draw the crisp, solid main logo on top
    fill(currentTint, 100);
    textSize(logoSize);
    text(logoText, pos.x, pos.y - h);
  }

  void changeColor() {
    // HSB color mode: Random Hue, High Saturation, High Brightness
    currentTint = color(random(360), random(70, 100), random(80, 100));
  }

  void updateSpeed(float newSpeed) {
    vel.normalize();
    vel.mult(max(0.5, newSpeed));
  }
}
