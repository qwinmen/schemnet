/* Управление включением и отключением насоса 600wt, используя два геркона и модуль реле */

int switchPinUp = 2; // к выводу D2 подключён геркон pointUp
int switchPinDown = 3; // к выводу D3 подключён геркон pointDown
#define PIN_RELAY 5          // Указываем, что вывод реле In1, подключен к реле цифровому выводу D5
bool pointUp = false;  //верхняя точка, геркон
bool pointDown = false; //нижняя точка, геркон

void setup() {
  pinMode(switchPinUp, INPUT); // задаём вывод в качестве входа (будем считывать с него)
  digitalWrite(switchPinUp, HIGH); // активируем внутренний подтягивающий резистор вывода
  
  pinMode(switchPinDown, INPUT); // задаём вывод в качестве входа (будем считывать с него)
  digitalWrite(switchPinDown, HIGH); // активируем внутренний подтягивающий резистор вывода
  
  pinMode(PIN_RELAY, OUTPUT); // Объявляем пин реле как выход
  digitalWrite(PIN_RELAY, HIGH); // Выключаем реле - посылаем высокий сигнал
  
  Serial.begin(9600); // задействуем последовательный порт
}

void loop() {
  int gUp = digitalRead(switchPinUp); // считываем показания с геркона
  if(gUp == 0)
  {
    pointUp = true;
    pointDown = false;
    Serial.print("pointUp:");
    Serial.println(pointUp);
  }
  int gDown = digitalRead(switchPinDown); // считываем показания с геркона
  if(gDown == 0)
  {
    pointDown = true;
    pointUp = false;
    Serial.print("pointDown:");
    Serial.println(pointDown);
  }
  
  if(pointUp == true)
  {
    //включить насос на откачку воды
    Serial.println("включить насос на откачку воды");
    digitalWrite(PIN_RELAY, LOW);  // Включаем реле
    pointDown = false;
  }
  
  if(pointDown == true)
  {
    //выключить насос
    Serial.println("выключить насос");
    digitalWrite(PIN_RELAY, HIGH);  // Выключаем реле
    pointUp = false;
  }

 delay(3000);
}
