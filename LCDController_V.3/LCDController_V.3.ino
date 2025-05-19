#include <LiquidCrystal_I2C.h>



// Set the LCD number of columns and rows
int lcdColumns = 16;
int lcdRows = 2;

// Set LCD address, number of columns and rows
// If you don't know your display address, run an I2C scanner sketch
LiquidCrystal_I2C lcd(0x27, lcdColumns, lcdRows);

// Define pin assignments
const int potPin = A0;   // Connect potentiometer to A0
const int buttonPin = 2; // Connect button to D2

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
    Serial.write(drinkIndex);
        
    // Display "Making your drink" on the LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Making");
    lcd.setCursor(0, 1);
    lcd.print(drinks[drinkIndex]);
    
    delay(5000);
    // Wait for the PIC to send confirmation that the drink is done
    char data = Serial.read();
    
    // Wait for the the PIC to clear the confirmation meaning the drink is in progress
    while (data == 0x01) {
      // Waiting while the drink is being made
      data = Serial.read();
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
