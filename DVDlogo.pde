class DVDlogo {
  PVector pos;
  PVector vel;
  
  // --- THE WORD LIST ---
  // Add or remove as many words as you want right here!
  String[] wordList = {"OBEY", "DOGE", "MOG", "MADS", "SIGMA", "AURA", "DVD"};
  String currentWord;
  
  float logoSize = 75;
  float w, h;
  color currentTint;
  
  // --- TRAIL SETTINGS ---
  int trailLength = 25; // How long the echo trail is
  PVector[] history;    // Array to remember past positions

  DVDlogo() {
    pos = new PVector(width / 2, height / 2);
    vel = PVector.random2D();
    
    // Pick the first word and calculate its specific dimensions
    changeWord();
    
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
    }
    if (pos.y - h <= 0 || pos.y >= height) {
      vel.y *= -1;
      hitY = true;
    }

    if (hitX || hitY) {
      changeColor();
      changeWord(); // Pick a new word!
      
      // CRITICAL MATH FIX: 
      // If the new word is longer than the old word, it might instantly overlap the wall.
      // This constraint pushes it back safely inside the screen bounds so it doesn't get stuck!
      pos.x = constrain(pos.x, 0, width - w);
      pos.y = constrain(pos.y, h, height);
    }

    if (hitX && (pos.y - h <= margin || pos.y >= height - margin)) {
       triggerConfetti(pos.x + w/2, pos.y - h/2);
    } else if (hitY && (pos.x <= margin || pos.x + w >= width - margin)) {
       triggerConfetti(pos.x + w/2, pos.y - h/2);
    }
  }

  void display() {
    textAlign(LEFT, TOP);

    // Draw the fading echo trail backwards
    for (int i = trailLength - 1; i >= 0; i--) {
      float alpha = map(i, 0, trailLength, 60, 0); 
      
      fill(currentTint, alpha);
      textSize(logoSize);
      text(currentWord, history[i].x, history[i].y - h);
    }

    // Draw the crisp, solid main word on top
    fill(currentTint, 100);
    textSize(logoSize);
    text(currentWord, pos.x, pos.y - h);
  }

  void changeColor() {
    // HSB color mode: Random Hue, High Saturation, High Brightness
    currentTint = color(random(360), random(70, 100), random(80, 100));
  }
  
  void changeWord() {
    // Pick a random word from the array
    int randomIndex = floor(random(wordList.length));
    currentWord = wordList[randomIndex];
    
    // Recalculate width/height because every word is a different size!
    textSize(logoSize);
    w = textWidth(currentWord);
    h = textAscent();
  }

  void updateSpeed(float newSpeed) {
    vel.normalize();
    vel.mult(max(0.5, newSpeed));
  }
}
