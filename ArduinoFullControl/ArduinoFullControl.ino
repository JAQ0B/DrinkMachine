#include <LiquidCrystal_I2C.h>


// initalliasation of variables
int CurrentPos = 1;
unsigned long startTime = 0;
int ButtonState;

// Set the LCD number of columns and rows
int lcdColumns = 16;
int lcdRows = 2;

// Set LCD address, number of columns and rows
LiquidCrystal_I2C lcd(0x27, lcdColumns, lcdRows);

// Define pin assignments
const int potPin = A0;   // Connect potentiometer to A0
const int buttonPin = 2; // Connect button to D2
const int MotorActivate = 3;
const int MotorDirection = 4;
const int GinValve = 5;
const int LemonValve = 6;
const int VodkaValve = 7;
const int OrangeJuiceValve = 8;
const int RaastofValve = 9;
const int Lift = 10;

// Set the Position of the valves
const int GinPos = 1;
const int VodkaPos = 2;
const int RaastofPos = 3;
const int LemonPos = 4;
const int OrangeJuicePos = 5;

// Time variables
const int MsBetweenIncrediences = 2000;




// Machine specific variables
int TimeBetweenValves = 1140;
int MsToMlConstant = 50;
// SKAL TESTES!!!!!!!! - Hvor længe er den om at kører en hel omgang / 5
// Hvor længe er den om at hælde 100ml / 100

 

// setting up drink indexing
int drinkIndex = 0;  // Index of the currently highlighted drink
String drinks[] = {"Gin lemon", "Gin juice", "Jordbaer Bomb", "Filur", "Vodka lemon", "Vodka juice", "Astronaut", "Long island"};
int numDrinks = sizeof(drinks) / sizeof(drinks[0]); // Number of drinks

// function declarations - Valves
void Gin(int ml){
  Serial.println("Gin valve function called");
  for (; GinPos > CurrentPos; CurrentPos++){
    GoLeft();
  }
  digitalWrite(GinValve, HIGH);
  Serial.println("Pouring");
  delay(ml * MsToMlConstant);
  digitalWrite(GinValve, LOW);
}

void Vodka(int ml){
  Serial.println("Vodka valve function called");
  for (; VodkaPos > CurrentPos; CurrentPos++){
    GoLeft();
  }
  digitalWrite(VodkaValve, HIGH);
  Serial.println("Pouring");
  delay(ml * MsToMlConstant);
  digitalWrite(VodkaValve, LOW);
}

void Raastof(int ml){
  Serial.println("Råstof valve function called");
  for (; RaastofPos > CurrentPos; CurrentPos++){
    GoLeft();
  }
  digitalWrite(RaastofValve, HIGH);
  Serial.println("Pouring");
  delay(ml * MsToMlConstant);
  digitalWrite(RaastofValve, LOW);
}

void Lemon(int ml){
  Serial.println("Lemon valve function called");
  for (; LemonPos > CurrentPos; CurrentPos++){
    GoLeft();
  }
  digitalWrite(LemonValve, HIGH);
  Serial.println("Pouring");
  delay(ml * MsToMlConstant);
  digitalWrite(LemonValve, LOW);
}

void OrangeJuice(int ml){
  Serial.println("Orange Juice valve function called");
  for (; OrangeJuicePos > CurrentPos; CurrentPos++){
    GoLeft();
  }
  digitalWrite(OrangeJuiceValve, HIGH);
  Serial.println("Pouring");
  delay(ml * MsToMlConstant);
  digitalWrite(OrangeJuiceValve, LOW);
}

//Function declaration - MotorMovement

void GoLeft(){
  Serial.println("Going left");
  digitalWrite(MotorActivate, HIGH);
  delay(TimeBetweenValves);
  digitalWrite(MotorActivate, LOW);
}

void GoRight(){
  Serial.println("Going right");
  digitalWrite(MotorActivate, HIGH);
  digitalWrite(MotorDirection, HIGH);
  delay(TimeBetweenValves);
  digitalWrite(MotorActivate, LOW);
  digitalWrite(MotorDirection, LOW);
}

void ReturnToStart(){
  // Display "Your drink is done" on the LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(drinks[drinkIndex]);
  lcd.setCursor(0, 1);
  lcd.print("Is ready");

  // Go back to start
  for (; CurrentPos > 1; CurrentPos--){
    GoRight();
    delay(300);
  }
}

// Setup serial, LCD screen and the pinmode
void setup() {
  Serial.begin(115200);
  // Initialize LCD
  lcd.init();
  // Turn on LCD backlight
  lcd.backlight();

  // Set button pin as input
  pinMode(buttonPin, INPUT);
  // Set the rest as output 
  pinMode(MotorActivate, OUTPUT);
  pinMode(MotorDirection, OUTPUT);
  pinMode(GinValve, OUTPUT);
  pinMode(LemonValve, OUTPUT);
  pinMode(VodkaValve, OUTPUT);
  pinMode(OrangeJuiceValve, OUTPUT);
  pinMode(RaastofValve, OUTPUT);
  pinMode(Lift, OUTPUT);
}

void loop() {
  // Read analog input from potentiometer
  int sensorValue = analogRead(potPin);

  // Map the potentiometer value to the range of drinks
  drinkIndex = map(sensorValue, 0, 1023, 0, numDrinks);

  // Ensure drinkIndex stays within the bounds
  drinkIndex = constrain(drinkIndex, 0, numDrinks - 1);

  int nextIndex = (drinkIndex + 1) % numDrinks;

  // Display the highlighted drink on the LCD
  lcd.setCursor(0, 0);
  lcd.print("-> ");
  lcd.print(drinks[drinkIndex]);
  lcd.print("                "); // Clear the rest of the line

  // Display the next drink on the LCD
  lcd.setCursor(0, 1);
  lcd.print("                "); // Clear the entire line
  lcd.setCursor(0, 1);
  if (nextIndex != 0) {
    lcd.print("   ");
    lcd.print(drinks[nextIndex]);
  }
  
  // Check if the button is pressed to select the drink
  if (digitalRead(buttonPin) == HIGH) {
    Serial.print("Selected Drink: ");
    Serial.println(drinks[drinkIndex]);
    
    // Display "Making your drink" on the LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Making");
    lcd.setCursor(0, 1);
    lcd.print(drinks[drinkIndex]);

    // Activate Lift, GO up.
    digitalWrite(Lift, HIGH);
    delay(3000);

    // Switch determins what drink to make - And calls the neede functions.
    switch(drinkIndex){
      case 0:
        // Make Gin Lemon
        Serial.println("Making Gin Lemon");
        Gin(50);
        delay(MsBetweenIncrediences);
        Lemon(200);
        delay(MsBetweenIncrediences);
        ReturnToStart();
        delay(1000);
        break;
        
      case 1:
        // Make Gin Juice
        Serial.println("Making Gin Juice");
        Gin(50);
        delay(MsBetweenIncrediences);
        OrangeJuice(200);
        delay(MsBetweenIncrediences);
        ReturnToStart();
        break;
        
      case 2:
        // Make Jordbær Bombe (Strawberry Bomb) https://raastoff.dk/drink/strawberry-bomb/
        Serial.println("Making Jordbær boombe");
        Raastof(20);
        delay(MsBetweenIncrediences);
        Vodka(20);
        delay(MsBetweenIncrediences);
        Lemon(100);
        delay(MsBetweenIncrediences);
        ReturnToStart();
        break;
        
      case 3:
        // Make Filur https://raastoff.dk/drink/frozen-filur/
        Serial.println("Making Filur");
        Raastof(60);
        delay(MsBetweenIncrediences); 
        OrangeJuice(80);
        delay(MsBetweenIncrediences);
        ReturnToStart();        
        break;
        
      case 4:
        // Make Vodka Lemon
        Serial.println("Making Vodka Lemon");
        Vodka(100);
        delay(MsBetweenIncrediences);
        Lemon(100);
        delay(MsBetweenIncrediences);
        ReturnToStart();
        break;
        
      case 5:
        // Make Vodka Juice
        Serial.println("Making VOdka Juice");
        Vodka(100);
        delay(MsBetweenIncrediences);
        OrangeJuice(100);
        delay(MsBetweenIncrediences);
        ReturnToStart();
        break;
        
      case 6:
        // Make Astronaut https://raastoff.dk/drink/astronaut-da/
        Serial.println("Making Astronaut");
        Raastof(60);
        delay(MsBetweenIncrediences);
        Lemon(150);
        delay(MsBetweenIncrediences);
        ReturnToStart();
        break;
        
      case 7:
        // Make Long Island
        Serial.println("Making Gin LongIsland");
        Gin(20);
        delay(MsBetweenIncrediences);
        Vodka(30);
        delay(MsBetweenIncrediences);
        Raastof(20);
        delay(MsBetweenIncrediences);
        Lemon(60);
        delay(MsBetweenIncrediences);
        OrangeJuice(60);
        delay(MsBetweenIncrediences);
        ReturnToStart();
        break;
    }
    // deactivate Lift, GO down
    digitalWrite(Lift, LOW);
    // Display "Your drink is done" on the LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(drinks[drinkIndex]);
    lcd.setCursor(0, 1);
    lcd.print("Is ready");
    delay(5000); 

  lcd.clear(); // Clear LCD for next iteration
  }
}
