/* Simulationsumgebung für Kettenreaktionen v.1.1
  von Alex Wellerstein (wellerstein@gmail.com), modifiziert & übersetzt von Elias Dahmen

  Programmiert mit Processing.js

  Der zugehörige Artikel: http://blog.nuclearsecrecy.com/2015/04/10/critical-mass/

*/

//basic settings
int numAtoms = 500; //total number of atoms to create
float enrichment = 90; //percent
float density = 1; //density of packing
float atomRadius = 4; //size of inert atoms
float atomRadiusf = 6; //size of fissile atoms
float neutronRadius = 1; //size of neutrons
int neutronLifetime = 35; //how long neutrons live before decaying
boolean neutronReflector = false; //neutron reflector
boolean showSplitting = false; //splitting animation — easier to render without it
boolean repulsiveEffect = true; //does fissioning cause nearby atoms to move?
boolean showRepulsiveEffect = true; //do we show the repulsive effect?
boolean spontaneousFission = false; //is there spontaneous fission?

//advanced options
int maxNeutronsPerFission = 3; //maximum number of neutrons per fission
float neutronSpeed = 5; //default speed of neutron
float neutronScatterSpeed = .9; //differential speed of neutron after scattering (multiplies by speed)
float neutronScatterSize = 1.2; //differential size of neutron after scattering (multiplies by neutronRadius)
boolean showCurrentFissions = true; //graph current fissions
boolean showTotalFissions = false; //graph total fissions
int scatterChance = 50; //chance of scattering as opposed to absorption (percent)
int scatterChancef = 25; //chance of scattering as opposed to fissioning (percent)
float repulsiveEffectRadius = 10; //size of the repulsive effect radius from a fission
float repulsiveEffectForce = 2; //strength of repulsive effect
int initiatorNeutrons = 5; //number of neutrons to create at center of initiator is clicked
float implodeAmount = 2; //factor by which the original diameter that implosion shrinks the reflector by
float implodeSpeed = 1; //speed that the implosion happens
int preScatter = 0; //number of times to pre-move atoms before launching -- this helps keep them from moving immediately after launched
int canvasWidth = 750; //resizes canvas
int canvasHeight = 650; //resizes canvas
float canvasFrameRate = 60; //framerate
float spontaneousFissionFissile = 1; //chance of a spontaneous fission in fissile material per frame, out of 1,000,000 (e.g. 1 = 1/1000000th of a chance);
float spontaneousFissionInert = 20; //chance of a spontaneous fission in inert material per frame, out of 1,000,000 (e.g. 1 = 1/1000000th of a chance);
float atomFriction = .1; //how much atoms slow down after being bumped
float atomMaxSpeed = 5; //maximum velocity along either vector, to keep things from getting crazy

boolean atomsImpartMomentum = false; //when atoms bump into each other, do they just move other atoms or impart momentum? toggling this off decrease physical realism but increases performance
boolean showButtons = false; //buttons for debugging in processing environment
boolean embedded = true; //turn off when in processing environment (adjusts how it interprets x,y mouse clicks)

//global objects

ArrayList Atoms; //the collection of atoms
ArrayList Neutrons; //the neutrons
ArrayList SplittingAtoms; //the animation used when the atoms split
ArrayList Repulsors; //the little pushing effects that happen when atoms split
Reflector reflector; //the neutron reflector (just one)

ArrayList FissionLines; //the lines that show current # of fissions on the bottom of the screen
ArrayList FissionLinesTotal; //the lines that show cumulative # of fissions on the bottom of the screen
ArrayList Buttons; //buttons used for debugging it in the Processing.js environment
ArrayList Dots; //just little dots I was using for debugging purposes

//counters
int FissileAtoms, TotalNeutrons, TotalFissions,CurrentFissions,LostAbsorption,LostDecay,totalScatters,fLine,reactionTimer,reactionTimerSince,framesSinceStart;
boolean reactionTimerOn, reactionTimerSinceOn;

//data list
String DataOutput = "";

//these "set" functions are used so that the web Javascript interface can modify variables in the code
void setInt(String varname, int value){
  switch(varname){
    case "numAtoms": numAtoms = value; break;
    case "neutronLifetime": neutronLifetime = value; break;
    case "maxNeutronsPerFission": maxNeutronsPerFission = value; break;
    case "scatterChance": scatterChance = value; break;
    case "scatterChancef": scatterChancef = value; break;
    case "initiatorNeutrons": initiatorNeutrons = value; break;
    case "preScatter": preScatter = value; break;
    case "canvasHeight": canvasHeight = value; break;
    case "canvasWidth": canvasWidth = value; break;
  }
}

void setFloat(String varname, float value){
  switch(varname){
    case "enrichment": enrichment = value; break;
    case "atomRadius": atomRadius = value; break;
    case "atomRadiusf": atomRadiusf = value; break;
    case "density": density = value; break;
    case "neutronRadius": neutronRadius = value; break;
    case "neutronSpeed": neutronSpeed = value; break;
    case "neutronScatterSpeed": neutronScatterSpeed = value; break;
    case "neutronScatterSize": neutronScatterSize = value; break;
    case "repulsiveEffectRadius": repulsiveEffectRadius = value; break;
    case "repulsiveEffectForce": repulsiveEffectForce = value; break;
    case "implodeAmount": implodeAmount = value; break;
    case "implodeSpeed": implodeSpeed = value; break;
    case "spontaneousFissionFissile": spontaneousFissionFissile = value; break;
    case "spontaneousFissionInert": spontaneousFissionInert = value; break;
    case "canvasFrameRate": canvasFrameRate = value; break;
  }
}

void setBool(String varname, boolean value){
  switch(varname){
    case "neutronReflector": neutronReflector = value; break;
    case "showSplitting": showSplitting = value; break;
    case "repulsiveEffect": repulsiveEffect = value; break;
    case "showRepulsiveEffect": showRepulsiveEffect = value; break;
    case "showCurrentFissions": showCurrentFissions = value; break;
    case "showTotalFissions": showTotalFissions = value; break;
    case "spontaneousFission": spontaneousFission = value; break;
    case "embedded": embedded = value; break;
  }
}

void getData() {
  return "Frame\tAktuelle Spaltungen\tGesamte Spaltungen\tAktive Neutronen\tGesamte Neutronen\n"+DataOutput;
}

//reset and reload
void reset() {
   for(int i=0; i< Neutrons.size();i++) { Neutrons.remove(i); }
   for(int i=0; i< Atoms.size();i++) { Atoms.remove(i); }
   for(int i=0; i< Buttons.size();i++) { Buttons.remove(i); }
   for(int i=0; i< SplittingAtoms.size();i++) { SplittingAtoms.remove(i); }
   for(int i=0; i< FissionLines.size();i++) { FissionLines.remove(i); }
   for(int i=0; i< FissionLinesTotal.size();i++) { FissionLinesTotal.remove(i); }
   for(int i=0; i< Repulsors.size();i++) { Repulsors.remove(i); }
   FissileAtoms = TotalNeutrons = TotalFissions = CurrentFissions = LostAbsorption= LostDecay= totalScatters= fLine = reactionTimer = 0;
   reactionTimerOn = reactionTimerSinceOn = false;
   setup();
}

//loads the setup
void setup() {
  size(750,650);
  frameRate(canvasFrameRate);
  framesSinceStart = 0;
  DataOutput = "";
  size(canvasWidth,canvasHeight);
  noStroke();
  smooth();
  int max_length = (height<width)?height*.9:width*.9; //max diameter of the field of atoms
  //initialize the atoms
  Atoms = new ArrayList();
  for(int i=0; i<numAtoms;i++) {
    //disk point picking
    float a = random(0,1);
    float b = random(0,1);
    if(b<a) { //swap a/b
      float c = a;
      a = b;
      b = c;
    }
    int centerx = b*((max_length/density)/2)*cos(2*PI*a/b)+(width/2);
    int centery = b*((max_length/density)/2)*sin(2*PI*a/b)+(height/2);
    Atoms.add(new Atom(centerx,centery,(random(100)<=enrichment?0:1),i));
  }

  //initialize other arraylists, reflector, buttons, etc.
  Dots = new ArrayList();
  SplittingAtoms = new ArrayList();
  Neutrons = new ArrayList();
  Repulsors = new ArrayList();
  if(neutronReflector) reflector = new Reflector();
  FissionLines = new ArrayList();
  FissionLinesTotal = new ArrayList();
  Buttons = new ArrayList();
  if(showButtons) {
    Buttons.add(new Button(10,height-30,100,20,"Neutroneninitiator"));
    Buttons.add(new Button(10,height-60,100,20,"Implodieren"));
    Buttons.add(new Button(width-110,height-30,100,20,"Neu Laden"));
  }
  for(int i=0; i<width;i=i+10) {
     FissionLines.add(new FissionLine(i,color(255,0,0,80)));
     FissionLinesTotal.add(new FissionLine(i+5,color(0,255,0,80)));
  }
  //pre-scatter -- arranges the atoms so they don't move when you first start up
  //disabled by default because it is super slow
  if(preScatter) {
    for(int x=0; x<preScatter;x++) {
      console.log("Prescattering ("+(x+1)+"/"+preScatter+")");
      for(int i=0; i< Atoms.size();i++) {
           Atoms.get(i).move();
      }
    }
  }
}

//main drawing function, runs every frame, calculates all movements and draws all stuff
void draw() {
  background(0);
  if(framesSinceStart>0||Neutrons.size()>0||CurrentFissions>0) {
    framesSinceStart++;
  }
  if(CurrentFissions>0||Neutrons.size()>0) {
    DataOutput+=str(framesSinceStart)+"\t"+str(CurrentFissions)+"\t"+str(TotalFissions)+"\t"+str(Neutrons.size())+"\t"+str(TotalNeutrons)+"\n";
  }
  if(showTotalFissions||showCurrentFissions) {
    for(int i=0;i<FissionLines.size();i++) {
      if(TotalFissions) {
        if((CurrentFissions==0&&fLine<5)||(CurrentFissions>0)) {
          if(CurrentFissions==0) { fLine++; } else { fLine=0;};
          if(i==FissionLines.size()-1) {
            if(showCurrentFissions) FissionLines.get(i).value = CurrentFissions;
            if(showTotalFissions) FissionLinesTotal.get(i).value = lerp(0,height*.99,(TotalFissions/(Atoms.size()+TotalFissions)));
          } else {
            if(showCurrentFissions) FissionLines.get(i).value = FissionLines.get(i+1).value;
            if(showTotalFissions) FissionLinesTotal.get(i).value = FissionLinesTotal.get(i+1).value;
          }
        }
      }
      if(showCurrentFissions) FissionLines.get(i).display();
      if(showTotalFissions) FissionLinesTotal.get(i).display();
    }
  }
  CurrentFissions = 0;
  if(reactionTimerOn) reactionTimer++;
  if(reactionTimerSinceOn) reactionTimerSince++;
  if(neutronReflector) {
    if(reflector.imploding) reflector.implode();
  }

  if(repulsiveEffect) {
    for(int i=0;i<Repulsors.size();i++) {
      Repulsor repulsor = (Repulsor) Repulsors.get(i);
      if(repulsor.dead) {
         Repulsors.remove(i);
      } else {
        repulsor.repulse();
        if(showRepulsiveEffect) {
          repulsor.display();
        }
      }
    }
  }
  /* //debugging stuff
  if(mousePressed) {
      Dots.add(new Dot(mouseX-window.scrollX,mouseY-window.scrollY));
  }
  for(int i=0; i< Dots.size();i++) {
    Dots.get(i).display();
  }
  */
  //main atom loop
  for(int i=0; i< Atoms.size();i++) {
    Atom atom = (Atom) Atoms.get(i);
    if(atom.dead==true) { //clean up dead atoms
       if(atom.type==0) FissileAtoms--;
       Atoms.remove(i);
     } else {
       atom.clicker(); //check for mouseclicks
       atom.move(); //move all atoms
       atom.display(); //show all atoms
     }
  }
  if(showSplitting) { //splitting animation
    for(int i=0;i<SplittingAtoms.size();i++) {
       SplittingAtom split = (SplittingAtom) SplittingAtoms.get(i);
       split.animate();
       if(split.dead==true) SplittingAtoms.remove(i);
    }
  }
  for(int i=0;i<Neutrons.size();i++) { //neutrons
     Neutrons.get(i).animate(); //one function does everything
     if(Neutrons.get(i).dead==true) Neutrons.remove(i); //clean up dead
  }
  if(neutronReflector) reflector.display(); //show reflector if enabled
  if(!CurrentFissions&&reactionTimerOn) {
      reactionTimerOn = false;
      reactionTimerSinceOn = true;
  }
  //text messages
  fill(255,250);
  textSize(28);
  textAlign(LEFT);
  text("Simulationsumgebung für Kettenreaktionen",10,42);
  textSize(12);
  text("von Alex Wellerstein (modifiziert & übersetzt von Elias Dahmen)",105,55);
  textSize(12);
  int textLine = 80;
  int textLineSize = 12;
  text("Gesamtzahl Atome: "+Atoms.size()+" ("+round(Atoms.size()/(TotalFissions+Atoms.size())*100)+"%)",10,textLine); textLine+=textLineSize;
  text("Spaltbare Atome: "+FissileAtoms+" ("+(Atoms.size()==0?"0":round(FissileAtoms/Atoms.size()*100))+"%)",10,textLine); textLine+=textLineSize;
  text("Nicht spaltbare Atome: "+(Atoms.size()-FissileAtoms),10,textLine); textLine+=textLineSize;
  text("Aktive Neutronen: "+Neutrons.size(),10,textLine); textLine+=textLineSize;
  text("Durch Absorbtion verlorene Neutronen: "+LostAbsorption,10,textLine); textLine+=textLineSize;
  text("Weitere verlorende Neutronen: "+LostDecay,10,textLine); textLine+=textLineSize;
  text("Gestreute Neutronen: "+totalScatters,10,textLine); textLine+=textLineSize;
  text("Gesamtzahl Neutronen: "+TotalNeutrons,10,textLine); textLine+=textLineSize;
  text("Gesamtzahl Spaltungen: "+TotalFissions+" ("+roundd(TotalFissions/(TotalFissions+Atoms.size())*100,1)+"%)",10,textLine); textLine+=textLineSize*1.5;
  text("Reaktionszeit: "+reactionTimer+" Frames",10,textLine); textLine+=textLineSize;

  //debugging buttons
  if(showButtons) {
    for(int i=0;i<Buttons.size();i++) {
       Buttons.get(i).display();
    }
    if(Buttons.get(0).clicked()) {
      initiator();
    }
    if(Buttons.get(1).clicked()&&neutronReflector) {
      implode();
    }
    if(Buttons.get(2).clicked()) {
      reset();
    }
  }
}
//initiator function -- makes a bunch of neutrons at the center
void initiator() {
  for(int i = 0; i<initiatorNeutrons;i++) {
      Neutrons.add(new Neutron(width/2,height/2));
  }
}
//implosion function -- tells the reflector to start imploding
boolean implode() {
  if(!neutronReflector) {
     return false;
  } else {
  if(!reflector.imploded&&!reflector.imploding) {
      reflector.imploding = true;
    }
    return true;
  }
}

float roundd(float number, float decimal) {
    return trim(nfs((round((number*pow(10, decimal))))/pow(10, decimal),1,decimal));
}

//main atom class
class Atom {
  float x, y; //position
  float vx = 0, vy = 0; //movement vectors
  float diameter; //size
  float type; //0 = 235, 1 = 238, 2 = 239
  int id; //internal id
  boolean dead = false; //alive/dead state

  //initialize the atom
  Atom(float xin, float yin, int typein, int idin) {
     x = xin;
     y = yin;
     type = typein;
     if(type==0) {
        diameter = atomRadiusf*2;
        FissileAtoms++;
     } else {
        diameter = atomRadius*2;    
     }
     id = idin;
  }

 //move this atom
 void move() {
    x+=vx;
    y+=vy;
    vx*=(1-atomFriction);
    vy*=(1-atomFriction);
    if(vx>atomMaxSpeed) vx = atomMaxSpeed;
    if(vy>atomMaxSpeed) vy = atomMaxSpeed;
    if(vx<-atomMaxSpeed) vx = -atomMaxSpeed;
    if(vy<-atomMaxSpeed) vy = -atomMaxSpeed;

   //check if we've run into the reflector
    if(neutronReflector) {
      //figure out how far from the center we are
      float mx = ((width/2)-x);
      float my = ((height/2)-y);
      float mdist = sqrt(mx*mx+my*my);
      //see if we're too far from the reflector
      if((mdist)>=reflector.diameter/2) {
        vx *= -1*repulsiveEffectForce*2;
        vy *= -1*repulsiveEffectForce*2;
        float angle = atan2(my,mx);
        x+=diameter*cos((angle));
        y+=diameter*sin((angle));
      }
    }

   //check to see if we've bumped any other atoms
   for(int i=0;i<Atoms.size();i++) {
      Atom atom = (Atom) Atoms.get(i);
      if(atom.id!=id) { //prevents self-interaction
        if(!atom.dead) {
             float mx = atom.x-x;
             float my = atom.y-y;
             float mdist = sqrt(mx*mx + my*my);
          if(mdist<=(atom.diameter/2 + diameter/2)){
             float mangle = atan2(my,mx);
             float targetX = x + cos(mangle)*((atom.diameter/2 + diameter/2));
             float targetY = y + sin(mangle)*((atom.diameter/2 + diameter/2));
             float ax = (targetX - atom.x) * (atomsImpartMomentum?repulsiveEffectForce:1);
             float ay = (targetY - atom.y) * (atomsImpartMomentum?repulsiveEffectForce:1);
             vx-=ax;
             vy-=ay;
             atom.vx+=ax;
             atom.vy+=ay;
           }
        }
      }
    }
    //spontaneous fission chance
    if(spontaneousFission&&!dead) {
      int spont = random(0,1000000);
      if(type==0) {
        if(spont<=spontaneousFissionFissile) fission();
      } else {
        if(spont<=spontaneousFissionInert) fission();
      }
    }
 }

  //fission this atom
   void fission() {
      if(!dead) {
        if(!reactionTimerOn) {
          reactionTimerOn = true; //start the reaction timer
          if(reactionTimerSinceOn) {
            reactionTimerSinceOn = false;
            reactionTimer+=reactionTimerSince;
            reactionTimerSince = 0;
          }
        }
        if(showSplitting) SplittingAtoms.add(new SplittingAtom(x,y,diameter,id));
        TotalFissions++;
        CurrentFissions++;
        int neutronCreate = random(0,maxNeutronsPerFission);
        for(int i = 0; i<neutronCreate;i++) {
          Neutrons.add(new Neutron(x,y));
        }
        if(repulsiveEffect) {
          Repulsors.add(new Repulsor(x,y));
        }
        dead = true;
      }
    }

  //code that renders the atom
  void display() {
     if(dead==false) {
       if(type==0) {
          fill(255,0,0,200);
       } else if (type==1) {
          fill(0,0,255,200);
       } else if (type==2) {
         fill(100,0,200,200);
       }
       ellipse(x,y,diameter,diameter);
     }
  }

 //code that checks for a mouse click
 void clicker() {
   if(!dead) {
     if(mousePressed) {
       float mx = (mouseX-(embedded?window.scrollX:0))-x;
       float my = (mouseY-(embedded?window.scrollY:0))-y;
       float mdist = sqrt(mx*mx + my*my);
       if(mdist<=diameter/2) fission();
      }
    }
  }

}

//just for debugging -- makes a dot
class Dot {
  float x,y;
  Dot(float xin, float yin) {
     x = xin; y = yin;
  }
  void display() {
    fill(255);
    ellipse(x,y,1,1);
  }
}

//debugging button -- simple button
class Button {
  float x,y,w,h;
  String btext;
  int clickedRecently = 0;
  Button(float xin, float yin, float win, float hin, String textin) {
    x = xin; y = yin; w = win; h = hin; btext = textin;
  }
  void display() {
    if(isOver()) {
       int calpha = 255;
    } else {
      int calpha = 200;
    }
    stroke(200,calpha);
    fill(180,calpha);
    rect(x,y,w,h);
    fill(0,calpha);
    textAlign(CENTER);
    textSize(14);
    text(btext,x+w/2,y+h/2+6);
    noStroke();
  }
  boolean isOver() {
      if(
         ( (mouseX-(embedded?window.scrollX:0) >= x) && (mouseX-(embedded?window.scrollX:0) <= x + w) ) &&
         ( (mouseY-(embedded?window.scrollY:0) >= y) && (mouseY-(embedded?window.scrollY:0) <= y + h) )
      ) {
        return true;
      } else {
        return false;
      }
  }
  void clicked() {
    if(clickedRecently>0) {
      clickedRecently--;
      return false;
    }
    if(isOver()&&mousePressed) {
      clickedRecently = 10;
      return true;
    } else {
      return false;
    }
  }

}

//neutron reflector class
class Reflector {
  float diameter; //current diameter
  float original_diameter; //original diameter
  boolean imploding = false; //are we imploding?
  boolean imploded = false; //did we implode?
  int implodeTimer = 0; //timer for implosion
  int implodeTimerMax = 100; //max time to implode
  Reflector() {
    int max_length = (height<width)?height*.9:width*.9;
    diameter = (max_length/density)+atomRadiusf;
    original_diameter = diameter;
  }
  void display() {
    stroke(150);
    noFill();
    strokeWeight(20);
    ellipse(width/2,height/2,diameter+18,diameter+18);
    noStroke();
    strokeWeight(1);
  }
  //calculates new size of reflector based on timer
  //what is neat is that the atoms will automatically reflect off of it and be compressed — nothing to do here regarding that!
  void implode() {
    implodeTimer++;
    if(implodeTimer>implodeTimerMax) {
      imploding = false;
      imploded = true;
    } else {
      float implodePer = implodeTimer/implodeTimerMax;
      diameter = lerp(original_diameter,original_diameter/implodeAmount,implodePer);
    }
  }
}

//line at the bottom of the screen
class FissionLine {
  int value = 0;
  float x;
  color c;
  FissionLine(float xin, color cin) {
    x = xin;
    c = cin;
  }
  void display() {
    if(value) {
      stroke(c);
      strokeWeight(5);
      strokeCap(SQUARE);
      line(x,height,x,height-value);
      strokeWeight(1);
      noStroke();
    }
  }
}

//animation of a splitting atom
class SplittingAtom {
  float x, y;
  float diameter;
  float dx, dy;
  float maxlife = 30;
  float life = 0;
  float id;
  float angle = random(0,360);
  boolean dead = false;
  SplittingAtom(float xin, float yin, float din, float idin) {
    x = xin;
    y = yin;
    diameter = din;
    id = idin;
    dx = diameter;
    dy = diameter;
  }

  void animate() {
    life++;
    //all this pushmatrix/translate/etc. crap is because
    //processing has a really irritating way of rotating things
    pushMatrix();
    translate(x, y);
    rotate(radians(angle));
    noStroke();
    float lifeper = life/maxlife;
    if(lifeper<.1) { //first 10% of animation is stretching
      fill(255,255,255-(255*(lifeper)));
       dx*=(1+(life/(maxlife*.1)));
       dy/=(1+(life/(maxlife*.1)));
      ellipse(0,0, dx, dy);
    } else if(lifeper<.5) { //then splitting until past 50% through
      dx-=.4;
      dy+=.4;
      fill(255,255,255-(255*(lifeper)));
      arc(-lifeper*15,0,dx, dy, radians(90), radians(270));
      arc(+lifeper*15,0,dx, dy, radians(270),radians(360+90));
    } else { //then kind of springing back after splitting
      dx-=.4;
      dy+=.4;
       fill(255,255,255-(255*(lifeper)),255-(255*(lifeper)));
      arc(-lifeper*15,0,dx, dy, radians(90), radians(270));
      arc(+lifeper*15,0,dx, dy, radians(270),radians(360+90));
    }
  popMatrix();
   if(life>=maxlife) {
     dead = true;
   }
  }
}

//little repulsive effect that can trigger when an atom fissions
//moves nearby atoms
class Repulsor {
  float x,y;
  boolean dead = false;
  int life = 0;
  int maxlife = 5;
  int diameter = repulsiveEffectRadius*2;
  Repulsor(float xin, float yin) {
    x = xin;
    y = yin;
  }
  void display() {
    life++;
    if(life>maxlife) {
      dead = true;
      return false;
    }
    noStroke();
    fill(lerpColor(color(255,255,0,200),color(255,0,0,200),life/maxlife));
    ellipse(x,y,diameter*(life/maxlife),diameter*(life/maxlife));
  }

  //moves the nearby atoms, makes them bounce a bit
  void repulse() {
    for(int i=0;i<Atoms.size();i++) {
      Atom atom = (Atom) Atoms.get(i);
      if(!atom.dead) {
          float mx = atom.x-x;
           float my = atom.y-y;
           float mdist = sqrt(mx*mx + my*my);
          if(mdist<=(atom.diameter/2 + diameter/2)){
             float mangle = atan2(my,mx);
             float targetX = x + cos(mangle)*((atom.diameter/2 + diameter/2));
             float targetY = y + sin(mangle)*((atom.diameter/2 + diameter/2));
             float ax = (targetX - atom.x) * repulsiveEffectForce;
             float ay = (targetY - atom.y) * repulsiveEffectForce;
             atom.vx+=ax;
             atom.vy+=ay;
          }
      }
    }
  }
}

//main neutron class
class Neutron {
  float x,y; //position
  float vx,vy; //movement vector
  boolean dead = false; //alive or dead
  int life = 0; //life counter
  int maxlife = neutronLifetime; //maximum life
  int diameter = neutronRadius*2; //diameter
  float angle = random(0,360); //initial angle (random)
  int speed = neutronSpeed; //initial neutron speed
  Neutron(float xin, float yin) {
    x = xin;
    y = yin;
    TotalNeutrons++;
    vx = cos(radians(angle)) * speed;
    vy = -(sin(radians(angle)) * speed);
  }
  void animate() {
    life++;
    if(life>=maxlife) {
      dead = true; LostDecay++; return false;
    }
    lifeper = life/maxlife;
      x+=vx;
      y+=vy;
     if(x>width||x<=0) { dead = true; LostDecay++; }
     if(y>height||y<=0) { dead = true; LostDecay++; }
    if(dead) return false;

  //check to see if the neutron has collided with an atom
   for(int i=0;i<Atoms.size();i++) {
      Atom atom = (Atom) Atoms.get(i);
        if(!atom.dead) {
             float mx = atom.x-x;
             float my = atom.y-y;
             float mdist = sqrt(mx*mx + my*my);
          if(mdist<=(atom.diameter/2 + diameter/2)){
             int scatter = random(0,100);
             if(atom.type == 0 && scatter<=scatterChancef || atom.type == 1 && scatter<=scatterChance || atom.type == 2) { //do we scatter?
               float mangle = atan2(my,mx);
               float targetX = x + cos(mangle)*((atom.diameter/2 + diameter/2));
               float targetY = y + sin(mangle)*((atom.diameter/2 + diameter/2));
               float ax = (targetX - atom.x);
               float ay = (targetY - atom.y);
               //get the new vector with scattering angle
               vx-=(ax);
               vy-=(ay);
               //now convert this back into an angle and apply the new speed for new vector
                angle = atan2(vy,vx);
                vx = cos(angle) * (neutronScatterSpeed*neutronSpeed);
                vy = -(sin(angle) * (neutronScatterSpeed*neutronSpeed));
               totalScatters++;
               diameter=neutronRadius*neutronScatterSize;
             } else { //not scattering -- either fission or absorb depending on atom type
               if(atom.type == 0) {
                 atom.fission();
               } else {
                  atom.type = 2; LostAbsorption++;
               }
               dead = true;
             }
           break;
           }
        }
     }

    //bounce off the neutron reflector if there is one
    if(neutronReflector) {
      float mx = ((width/2)-x);
      float my = ((height/2)-y);
      float mdist = sqrt(mx*mx+my*my);
      if((mdist)>=reflector.diameter/2) {
        vx *= -1;
        vy *= -1;
        angle = atan2(my,mx);
        x+=diameter*cos((angle));
        y+=diameter*sin((angle));
      }
    }
    stroke(255,255,255,200-(200*lifeper));
    fill(255,255,255,190-(190*lifeper));
    ellipse(x,y,diameter,diameter);
    noStroke();
  }
}
