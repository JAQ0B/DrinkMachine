#include <LiquidCrystal_I2C.h>

String data;
int analogValue;

// Set the LCD number of columns and rows
int lcdColumns = 16;
int lcdRows = 2;

// Set LCD address, number of columns and rows
// If you don't know your display address, run an I2C scanner sketch
LiquidCrystal_I2C lcd(0x27, lcdColumns, lcdRows);

// Define pin assignments
const int potPin = A0;   // Connect potentiometer to A0
const int buttonPin = 2; // Connect button to D2
const int CommunicationPin = 4;
const int AnalogSendPin = 5;

int drinkIndex = 0;  // Index of the currently highlighted drink
String drinks[] = {"Gin Hass", "Gin lemon", "Rom og cola", "Vodka lemon", "Vodka juice", "Vodka cola", "Astronaut", "Long island"};
int numDrinks = sizeof(drinks) / sizeof(drinks[0]); // Number of drinks

void setup() {
  Serial.begin(115200);
  // Initialize LCD
  lcd.init();
  // Turn on LCD backlight
  lcd.backlight();

  // Set button pin as input
  pinMode(CommunicationPin, INPUT);
  pinMode(AnalogSendPin, OUTPUT);
  pinMode(buttonPin, INPUT);
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

  // Display the next drink on the LCD
  lcd.setCursor(0, 1);
  if (nextIndex != 0) {
    lcd.print("   ");
    lcd.print(drinks[nextIndex]);
  }
  
  // Check if the button is pressed to select the drink
  if (digitalRead(buttonPin) == HIGH) {
    Serial.print("Selected Drink: ");
    Serial.println(drinks[drinkIndex]);
    
    
  // Calculate the analog value based on the drink index
  analogValue = (drinkIndex * 32) + 16;  // Each segment is 32, and we add 16 to get the midpoint
  
  // Send analogValue to the PIC
  analogWrite(AnalogSendPin, analogValue / 4);
  delay(1000);

    
    while (digitalRead(CommunicationPin) == 0) {
      digitalRead(CommunicationPin);
      delay(400);
      // Waiting while the drink is being made
    }
    analogWrite(AnalogSendPin, 0);  
    // Display "Making your drink" on the LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Making");
    lcd.setCursor(0, 1);
    lcd.print(drinks[drinkIndex]);

    while (digitalRead(CommunicationPin) == 1) {
      digitalRead(CommunicationPin);
      delay(400);
    } 
    

    // Display "Your drink is done" on the LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(drinks[drinkIndex]);
    lcd.setCursor(0, 1);
    lcd.print("Is ready");
    delay(10000); // Display for 10 sec before returning to main loop
  }

  delay(100); // Adjust delay as needed
  lcd.clear(); // Clear LCD for next iteration
}
