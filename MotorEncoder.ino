int pinChannelA = 2;
int pinChannelB = 3;
float count = 0;

int in1 = 5;
int in2 = 4;
int ena = 6;

float speed = 0;
bool newSerialInput = false;

// Variables filtro
const int win_size = 6; // Tamaño de la ventana
float readings[win_size]; // Array para almacenar las lecturas
int index = 0;          // Índice inicial
float sum_readings = 0; // Suma inicial de las lecturas
float average = 0;      // Valor promedio filtrado

void setup() {
  pinMode(in1, OUTPUT);
  pinMode(in2, OUTPUT);
  pinMode(ena, OUTPUT);
  Serial.begin(2000000);

  // Inicializar filtro
  for (int i = 0; i < win_size; i++) {
    readings[i] = 0.0;
  }

  attachInterrupt(digitalPinToInterrupt(pinChannelA), callback_A, FALLING);
  attachInterrupt(digitalPinToInterrupt(pinChannelB), callback_B, FALLING);
  
  cli();
  TCCR1A = 0;  
  TCCR1B = 0;  
  TCNT1  = 0;  
  OCR1A = 3124; // 20 Hz

  TCCR1B |= (1 << WGM12);
  TCCR1B |= (1 << CS12);
  TIMSK1 |= (1 << OCIE1A);
  sei();
}

ISR(TIMER1_COMPA_vect) {
  // Calcular velocidad, ajustar fórmula según resolución del encoder y tiempo de muestreo
  speed = (count * 20) / (22 * 26); 

  // Filtro de media móvil
  float NewData = speed;
  sum_readings = sum_readings - readings[index]; // Actualizar la suma: restar la lectura antigua y sumar la nueva
  readings[index] = NewData;
  sum_readings = sum_readings + NewData;
  average = sum_readings / win_size; // Calcular el promedio
  index = (index + 1) % win_size;

  count = 0; // Reiniciar contador
}

void callback_A() {
  if (digitalRead(pinChannelB) == 1) {
    count++;
  } else {
    count--;
  }
}

void callback_B() {
  if (digitalRead(pinChannelA) == 0) {
    count++;
  } else {
    count--;
  }
}

void loop() {
  if (Serial.available() > 0) {
    String inputString = Serial.readStringUntil('\n');
    float numeroRecibido = inputString.toFloat();

    // Ajuste de valores recibidos para controlar el motor
    if (numeroRecibido >= -1 && numeroRecibido <= 1) {
      numeroRecibido = numeroRecibido * 255;
    } else if (numeroRecibido > 1) {
      numeroRecibido = 255;
    } else if (numeroRecibido < -1) {
      numeroRecibido = -255;
    }
    
    if (numeroRecibido > 0) {
      digitalWrite(in1, HIGH);
      digitalWrite(in2, LOW);
      analogWrite(ena, numeroRecibido);
    } else if (numeroRecibido < 0) {
      digitalWrite(in1, LOW);
      digitalWrite(in2, HIGH);
      analogWrite(ena, -numeroRecibido);  
    } else {
      digitalWrite(in1, LOW);
      digitalWrite(in2, LOW);
      analogWrite(ena, 0);
    }
    
    newSerialInput = true;  
  }

  if (newSerialInput) {
    Serial.println(average); // Imprimir valor filtrado de la velocidad
    newSerialInput = false; 
  }
}
