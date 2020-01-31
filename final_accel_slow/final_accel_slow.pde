// sound control
import ddf.minim.*;
Minim minim;
AudioInput in;
float soundlevel;
// circles
ArrayList<Circle> circleList = new ArrayList();
Circle initialCircle;
// maximum number of clock levels, must be in {1,2,3}
int clockLevels = 3;
// bola
Bola[] bolaList= new Bola[100];
int quantas=40;
int bolaTrailSize = 30;
void setup() {
  frameRate(20);
  // window size
  size(1280, 768);
  // centre of initial circle
  PVector centre = new PVector(width/2, height/2);
  // radius of initial circle
  float radius = 160;
  // define initial circle
  initialCircle = new Circle(centre, radius, 1);
  circleList.add(initialCircle);
  // initialize minim object
  minim = new Minim(this);
  // initialize audio input
  in = minim.getLineIn(Minim.MONO, 512);  
  //smooth(500);
  //background(#1b3a98);
  for (int i=0; i<quantas; i++) {
    bolaList[i] = new Bola((int)random(4, 9)*20);
  }
  //
}

void draw() {
  for (int i=0; i<quantas; i++) {
    for (int j=0; j<quantas; j++) {
      if (i != j) bolaList[i].calcula(bolaList[j]);
    }
  }
  for (int i=0; i<quantas; i++) {
    bolaList[i].move();
    bolaList[i].draw();
  }
  //we save the current audio level to a variable.
  soundlevel = in.right.level();
  //level is between 0-1, which is too small to use, so we map it to a new range 0-400. 
  //You can try a different range.
  // re-map sound level
  soundlevel = map(soundlevel, 0, 1, 0, 1300);
  // render clock
  initialCircle.show(1);
  // update three clocks; arraylist index starts at 0;
  // current clock level = i+1
  for (int i=0; i<circleList.size(); i++) {
    Circle K = circleList.get(i);
    K.show(i+1);
  }
  fade(7);
}

void mousePressed() {
  // left clicks add one more level
  if (mouseButton==LEFT) {
    // only if maximum level has not been reached
    if (circleList.size() < clockLevels) {
      // draw subcircle
      Circle subCircle = new Circle(circleList.get(circleList.size()-1).mloc, 2*circleList.get(circleList.size()-1).r/3, circleList.size()+1);
      circleList.add(subCircle);
    }
  }
  // other clicks remove the last level of clock
  else if (circleList.size() > 1) {
    circleList.remove(circleList.size()-1);
  }
}

class Circle {
  PVector loc, mloc = new PVector(0, 0);
  int level;
  float r;
  float theta_sec, theta_min, theta_hr;
  float secondzero = second();
  // 0 radians is at 3 o'clock in polar coordinates, subtract pi/2
  // angles in radians for seconds, minutes, and hours
  Circle(PVector location, float radius, int lvl) {
    this.loc = location;
    this.r = radius;
    this.level = lvl;
  }
  void show(int level) {
    theta_sec = map(secondzero + millis()/1000., 0, 60, 0, PI*2) - PI/2;
    theta_min = map(minute() + second()/60., 0, 60, 0, PI*2) - PI/2; 
    theta_hr  = map(hour() + minute()/60., 0, 24, 0, PI*4) - PI/2;
    // rescale radius and add sound level dependence
    float reff = r * exp( soundlevel/r);
    switch (level) {
    case 1:
      mloc.x = loc.x+reff*cos(theta_sec);
      mloc.y = loc.y+reff*sin(theta_sec);
      break;
    case 2:
      mloc.x = loc.x+reff*cos(theta_min);
      mloc.y = loc.y+reff*sin(theta_min);
      break;
    case 3:
      mloc.x = loc.x+reff*cos(theta_hr);
      mloc.y = loc.y+reff*sin(theta_hr);
      break;
    }
    strokeWeight(1);
    noFill();
    stroke(255, 100);
    ellipse(loc.x, loc.y, 2*reff, 2*reff);  
    line(loc.x, loc.y, mloc.x, mloc.y);
    fill(#0052cc);
    ellipse(mloc.x, mloc.y, 7, 7);
  }
}

class Bola {
  float px, py, vx, vy, m, tam;
  color cor;
  PVector locationvect = new PVector(0, 0), loc = new PVector(0, 0);
  ArrayList<PVector> traillist=new ArrayList<PVector>(), trail=new ArrayList<PVector>();
  int trailLength;
  Bola(float _m) {
    m=_m;
    px=random(width);
    py=random(height);
    vx=0;
    vy=0;
    cor = color((int)random(50, 255), (int)random(50, 255), (int)random(50, 255));
    tam= 2;//random(5,25)
    locationvect = new PVector(px,py);
    traillist.add(locationvect);
    this.loc = locationvect;
    this.trail = traillist;
  }
  void move() {
    px+=vx;
    py+=vy;
    //vx*=.99999;
    //vy*=.99999;
    locationvect = new PVector(px,py);
    traillist.add(locationvect);
    this.loc = locationvect;
    this.trail = traillist;
  }

  void calcula(Bola b) {
    float d =dist(px, py, b.px, b.py);
    float atraction = sqrt((m * b.m)/pow(d, 2));
    // change power below to control strength of gravitational interactions
    // best within [0, 1]
    float accel = pow(b.m/pow(d, 2), 0.6);
    //vx += atraction * (b.px - px)/d/m;
    //vy += atraction * (b.py - py)/d/m;
    vx += accel * (b.px - px)/d * 0.04;
    vy += accel * (b.py - py)/d * 0.04;
  }
  void draw() {
    print("trail size is");
    print(trail.size());
    trailLength = trail.size() - 2;
    for (int i = 0; i < trailLength; i++) {
      PVector currentTrail = trail.get(i);
      PVector previousTrail = trail.get(i + 1);
      strokeWeight(0);
      stroke(cor, 255*i/trailLength);
      line(
        currentTrail.x, currentTrail.y,
        previousTrail.x, previousTrail.y
      );
    }
    noStroke();
    fill(cor);
    ellipse(px, py, tam, tam);
    if (trailLength >= bolaTrailSize) {
      trail.remove(0);
    }
  }
}

void fade(int trans) {
  fill(#000033, trans);
  rect(0, 0, width, height);
}

void stop() {
  in.close();
  minim.stop();
  super.stop();
}