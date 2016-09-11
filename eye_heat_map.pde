import gifAnimation.*;

Table eyeTable, eventTable;
int curr; // the index of current row in the eye data table
int nextStim; // the index of next stimulus to plot
float stimX, stimY; //prev stim pos (for erasure purposes)
int status; // indicates event (stimulus), red focus sphere, or nothing
float size; // size of stimulus
float circX, circY, circSize; //the current white circle, pos & size
boolean erased; //if last event was erased
boolean stimChange; //indicates need to update info (when status changes)
int lastStim; //1 = torus, 2 = sphere
String[] info; //angle spawned, etc  
boolean playing; // for play/pause
int incr; //1 or -1 based on forwards or rewind
float scale, xOffset, yOffset; //to fit in window nicely, and take care of negative positions
float initialFrameRate; //framerate on start
float speed;
boolean on;

GifMaker gifExport;
int frameNum;

void setup() {
  size(1000, 500);
  surface.setResizable(true);
  background(100, 100, 100, 20);

  eyeTable = loadTable("TorusFlashTest.Output.006.DATA.6.10.16.5.7.txt", "header,tsv");
  //eventTable = loadTable("TorusTest.Output.005.PERIPHERYTRIAL.6.9.12.42.30.txt", "header,tsv");
  
   gifExport = new GifMaker(this, "heatmpap_export2.gif");
   frameNum=0;

  curr = 0;
  circX = 0;
  circY = 0;
  circSize = 2;
  nextStim = 0;
  status = 0;
  size = 1;
  erased = false;
  info = new String[3];
  info[0] = "";
  info[1] = "";
  info[2] = "";
  playing = true;
  on = true;
  incr = 1;
  stimChange = true;
  lastStim = 0;

  scale = 0.3;
  xOffset = 200;
  yOffset = 100;
  initialFrameRate = 60;
  frameRate(initialFrameRate);
  speed = 1.0;
}

void draw() {

    
  TableRow row  = eyeTable.getRow(curr);
  float time = row.getFloat("Unity time");
  time = round(time * 100)/100.00;

  drawEyeMovement(row);

  status = row.getInt("status ");
  updateInfo(row); 

  //refresh status info
  noStroke();
  fill(100, 100, 100);
  rect(0, 480, 1000, 20);
  rect(20, 20, 50, 20);

  fill(255);
  textSize(11);
  text("time: " + time, 40, 480, 100, 20);
  text("user response: " + info[0], 150, 480, 300, 20);
  text("spawn angle: " + info[1], 450, 480, 300, 20);
  text("kill angle: " + info[2], 750, 480, 300, 20);
  text("" + speed + "x", 30, 20, 50, 20); 

  if (status == 1) { //red focus sphere
    eraseLastEvent();

    stimX = row.getFloat(" objX ");
    stimY = row.getFloat("objY ");
    size = 1;

    fill(255, 100, 100);
    ellipse(stimX * scale + xOffset, stimY * scale + yOffset, 15 * size, 15 * size);
    erased = false;
  } else if (status == 2) { //torus
    eraseLastEvent();
    lastStim = 1;

    stimX = row.getFloat(" objX ");
    stimY = row.getFloat("objY ");
    size = row.getFloat("Target Size");

    stroke(100, 100, 255);
    strokeWeight(5 * size);
    fill(100, 100, 100);
    ellipse(stimX * scale + xOffset, stimY * scale + yOffset, 15 * size, 15 * size);
    size += 5 * size; 
    erased = false;
  } else if (status == 3) { //circle
    eraseLastEvent();
    lastStim = 2;

    stimX = row.getFloat(" objX ");
    stimY = row.getFloat("objY ");
    size = row.getFloat("Target Size");

    noStroke();
    fill(100, 100, 255);
    ellipse(stimX * scale + xOffset, stimY * scale + yOffset, 15 * size, 15 * size);
    erased = false;
  } else {   
    if (!erased) {
      //erase last event
      eraseLastEvent();
      stimX = row.getFloat(" objX ");
      stimY = row.getFloat("objY ");
    }
  }

  //fade effect
  if (millis() % 10 == 0 ) {
    noStroke();
    fill(100, 100, 100, 100);
    rect(0, 0, 1000, 500);
  }

  curr += incr;
  if (time > 70){
   gifExport.addFrame();
  }
  if (time > 110) {
   gifExport.finish(); 
  }
   //frameNum++;
   //println(frameNum);

  if (curr >= eyeTable.getRowCount()) {
    on = false;
    noLoop();
    //gifExport.finish();
  }
}

/**
 * Draw the eye movement as white circles and lines in between
 */
void drawEyeMovement(TableRow row) {
  float eyex = row.getFloat("eye screen x"), 
    eyey = row.getFloat("eye screen z");
  //println(eyex + ", " + eyey);

  float dx = circX - eyex, 
    dy = circY - eyey;

  if (abs(dx) < 30 && abs(dy) < 30) {
    circSize += 0.1; //grow circle
  } else {
    //draw line to new circle
    strokeWeight(1);
    stroke(200);
    line(circX * scale + xOffset, circY * scale + yOffset, 
      eyex * scale + xOffset, eyey * scale + yOffset);

    //set new circle info
    circX = eyex;
    circY = eyey;
    circSize = 2;
  }

  //draw circle
  stroke(255);
  fill(255);
  ellipse(circX * scale + xOffset, circY * scale + yOffset, circSize, circSize);
}

/**
 * Erase overlast event (focus spheres & stimuli)
 */
void eraseLastEvent() {
  noStroke();
  fill(100, 100, 100);
  ellipse(stimX * scale + xOffset, stimY * scale + yOffset, 16 * size, 16 * size);
  erased = true;
}

/**
 * Update user response info and stimulus info
 */
void updateInfo(TableRow row) {
  int response = row.getInt("Button");

  boolean eyeMove = false;//row.getString("").equals("True");

  if (status == 1) {
    stimChange = true;
  }

  if (stimChange) {
    if (response == 0) {
      info[0] = "no response";
    } else {
      stimChange = false;

      if (response == lastStim) {
        info[0] = "correct response";
      } else {
        info[0] = "incorrect response";
      }

      fill(255, 255, 50);
      noStroke();
      rect(150, 450, 30, 30);
      textSize(15);
      text(info[0], 190, 470, 100);
    }

    //if (eyeMove) {
    //  info[0] += " + look";
    //} else {
    //  info[0] += " + no look";
    //}
  }

  info[1] = "" + row.getFloat("Spawn Angle");
  info[2] = "" + row.getFloat("Kill Angle");
}

void keyPressed() {
  float slomoFactor = 0.5;

  if (key == CODED) {
    if (keyCode == DOWN) { //slo-mo
      speed -= slomoFactor;
      frameRate(initialFrameRate * speed);
    } 
    if (keyCode == UP) { //fast fwd
      speed += slomoFactor;
      frameRate(initialFrameRate * speed);
    } else if (keyCode == LEFT) { //rewind
      incr = -1;
      if (!playing) {
        redraw();
      }
    } else if (keyCode == RIGHT) { //forwards
      incr = 1;
      if (!playing && on) {
        redraw();
      }
    }
  }

  //toggles play/pause
  if (key == ' ') {
    if (playing) {
      noLoop();
      playing = false;
    } else {
      loop(); 
      playing = true;
    }
  }
}