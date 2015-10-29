//  ToDo Обработка событий в отдельных потоках - 
//  с callback'ами или без них


unit LEGORobot;

interface

{$reference 'NKH.MindSqualls.dll'}

uses
  NKH.MindSqualls, Timers;


//  Предварительное описание класса "робот" - для определения процедурного
//  типа данных
type MyRobot = class;

//  Процедурный тип - для обработки событий
RoboProc = procedure(Robot : MyRobot);

SensorType = (sNone, sUltrasonic, sTouch, sLight, sColor);
MotorPort = (PortA, PortB, PortC);

/// <summary>
/// Класс мотора
/// </summary>
RoboMotor  = class(NKH.MindSqualls.NxtMotor) 
  private
    /// <summary>
    /// Объект для представления мотора
    /// </summary>
    //  motor : NKH.MindSqualls.NxtMotor;
    /// <summary>
    /// Контроллер робота
    /// </summary>
    //brick : NKH.MindSqualls.NxtBrick;
    /// <summary>
    /// Порт мотора
    /// </summary>
    //port  : NKH.MindSqualls.NxtMotorPort;
    /// <summary>
    /// Количество оборотов мотора
    /// </summary>
    /// <returns>Число оборотов, совершенное мотором</returns>
    function GetTachoCount : integer;
    /// <summary>
    /// Проверка состояния мотора
    /// </summary>
    /// <returns>True, если мотор вращается</returns>

    procedure SetBrick(brick : NKH.MindSqualls.NxtBrick);
    begin
      Self.Brick := brick;
    end;
    procedure SetPort(port : NKH.MindSqualls.NxtMotorPort);
    begin
      Self.Port := port;
    end;
    
  public
    constructor Create;
    function IsRunning : boolean;
    function Status : string;
    procedure Run(power : shortint; tachoLimit : longword) ;override;
    procedure Stop;
    procedure Coast;
    procedure Brake;
    procedure Reset;
    procedure WaitFor;
    
    property TachoCount : integer read GetTachoCount;
    property Running : boolean read IsRunning;
end;    
  
{Ultrasonic = class(NKH.Mindsqualls.NxtUltrasonicSensor)
  
  public
    Constructor Create;
    
end;}



/// <summary>
/// Класс для работы с роботом LEGO Mindstorms NXT
/// </summary>
MyRobot = class
  public
    //  Моторы - по именам    
    motA, motB, motC : RoboMotor;
    //  Таймер для обработки событий
    readTimer : Timer;
    //  Список обработчиков событий
    handlers : array of RoboProc;        //  массив обработчиков - событийный
    
    //  Массив признаков для инициализации сенсоров
    sns      : array [1..4] of SensorType;
    //  "Кирпич" - основной объект для работы с роботом
    //  Экземпляр создается в методе connect, иначе с портами проблема
    brick : NxtBrick;  
    
    
    motorRunning : boolean;    
    
    procedure setAction(v: RoboProc);    //  добавление обработчика
    procedure executeActions;

    //procedure addMotorA(m : RoboMotor);
    function getMotorA : RoboMotor;
    //procedure addMotorB(m : RoboMotor);
    function getMotorB : RoboMotor;
    //procedure addMotorC(m : RoboMotor);
    function getMotorC : RoboMotor;

    function getDistance : byte;
    function getLight : byte;
    function getColor : string;

    //  Инициализирует сенсоры по массиву sns
    procedure InitSensors;
    
    
  public
    property MotorA : RoboMotor read getMotorA;
    property MotorB : RoboMotor read getMotorB;
    property MotorC : RoboMotor read getMotorC;

    //  Свойство "действие" - позволяет заполнять массив
    property Action : RoboProc write setAction;

    property Distance : byte read getDistance;
    property Light : byte read getLight;
    property Color : string read getColor;
    
    
    constructor Create;
    destructor Destroy;
    begin
      brick.Disconnect;
      writeln('Disconnect command');
    end;
    
    function Connect(SerialPortNumber : byte := 0) : boolean;
    function Disconnect : boolean;

    procedure Stop;
    
    //procedure CheckMotor;

    //  Добавляет сенсор 
    procedure AddSensor(sType : sensorType; sPort : integer);

    // Добавляет моторчик на указанный порт
    //procedure AddMotor(mPort : motorPort);

    
    //  Устанавливает интервал опроса сенсоров
    procedure SetInterval(interval : integer);
end;

implementation

uses {System, System.Text,}System.IO.Ports;

//----------------Реализация методов мотора-------------------------------------
constructor RoboMotor.Create;
  begin
    //  Пока мотор не "подцеплен" к кирпичу - внутренний объект пуст
    //  создание объекта происходит при привязке к собственно роботу
    //motor := nil;
    //brick := nil;
    //port := NKH.MindSqualls.NxtMotorPort.All;
  end;

procedure RoboMotor.Run(power : shortint; tachoLimit : longword);
  begin
    inherited Run(power, tachoLimit);
  end;
  
procedure RoboMotor.Stop;
  begin
    Coast;
    Idle
  end;
  
procedure RoboMotor.Coast;  
  begin
    inherited Coast;
  end;
  
procedure RoboMotor.Brake;
  begin
    inherited Brake;
  end;
  
procedure RoboMotor.Reset;
begin
  ResetMotorPosition(false);
end;  
  
function RoboMotor.GetTachoCount : integer;
    begin
      var motorState := Brick.CommLink.GetOutPutstate(port);
      if (brick <> nil) and motorState.HasValue then 
        Result := motorState.Value.RotationCount
      else
        Result := -MaxInt;
    end;
    
function RoboMotor.IsRunning : boolean;
begin
  Result := false;
  if (brick<>nil) then 
    begin
      
      var statusValues := brick.CommLink.GetOutputState(port);
      if statusValues.HasValue and 
        (statusValues.Value.runState = NKH.MindSqualls.NxtMotorRunState.MOTOR_RUN_STATE_RUNNING)
        //(statusValues.Value.mode.HasFlag(NKH.MindSqualls.NxtMotorMode.MOTORON))
        //(statusValues.Value.regulationMode <> NKH.MindSqualls.NxtMotorRegulationMode.REGULATION_MODE_IDLE)
        then
          Result := true;
    
        //writeln('MA : ',statusValues.ToString);
        {writeln('MA : ',statusValues.Value.mode);
        writeln('MA : ',port);      if statusValues.HasValue and 
        (statusValues.Value.runState = NKH.MindSqualls.NxtMotorRunState.MOTOR_RUN_STATE_RUNNING) and
        (statusValues.Value.mode = NKH.MindSqualls.NxtMotorMode.MOTORON) then
}
        //writeln;writeln;writeln;writeln;writeln;writeln;
    end;
end;

procedure RoboMotor.WaitFor;
begin
  //  Попробовать исправить!!!!!!
  //brick.CommLink.GetOutputState
  while IsRunning do;
    //sleep(10);
end;

function RoboMotor.Status : string;
begin
  Result :=  brick.CommLink.GetOutputState(port).ToString;
end;


//------------------------Реализация методов робота-----------------------------
constructor MyRobot.Create;
begin
  brick := nil;
  readTimer := nil;
  //  readTimer := new Timer(50,executeActions);
  //  Заполняем поля - пока что пустые, автоматически определить
  //  наличие сенсора или мотора сложно или невозможно
  MotA := nil;
  MotB := nil;
  MotC := nil;
  for var i:=1 to 4 do
    sns[i] := sNone;
end;

function getPortNumberFromString(portName : string) : byte;
  var port : integer;
begin
  while (portName.Length>0) and ((portName[1]<'0') or (portName[1]>'9')) do
    Delete(portName,1,1);
  if TryStrToInt(portName,port) then
    Result := port
  else
    Result := -1;
end;


function MyRobot.Connect(SerialPortNumber : byte) : boolean;
begin
  Result := false;
  if SerialPortNumber <> 0 then
    //  Если указан номер порта для подключения
    try
      brick := new NxtBrick(NxtCommLinkType.Bluetooth, SerialPortNumber);
      //brick.Sensor4 := new NxtUltrasonicSensor(); brick.Sensor4.PollInterval := 500; sns[4] := sUltrasonic;
      InitSensors;
      writeln('Пытаюсь подключиться к указанному порту - ',SerialPortNumber.ToString);
      brick.Connect;
      if brick.IsConnected then 
        begin
          writeln('Получилось 1 - ',SerialPortNumber.ToString);
          writeln('Возвращаем true...');
          Result := true;
        end;
    except
      brick := nil;
    end
  else
    begin
      //  Иначе пробуем найти порт для подключения самостоятельно - перебором
      writeln('Пытаемся найти порты...');
      var ports := SerialPort.GetPortNames();
      for var i := ports.Length-1 downto 0 do
        try
          var s1 := getPortNumberFromString(ports[i]);
          writeln(s1);
          brick := new NxtBrick(NxtCommLinkType.Bluetooth, getPortNumberFromString(ports[i]));
          //brick.Sensor4 := new NxtUltrasonicSensor(); brick.Sensor4.PollInterval := 500; sns[4] := sUltrasonic;
          writeln('Пытаюсь подключиться!!!!!!!!!!!!!!!!!!!!! - ',getPortNumberFromString(ports[i]));
          InitSensors;
          brick.Connect;
          if brick.IsConnected then 
            begin
              writeln('Получилось - '+ports[i]);
              Result := true;
            end;
        except
          brick := nil;
        end;
  end;
  writeln('Проходим точку : 123');
  if Result then
    begin
      //  Если подключились, то создаем таймер для обработки событий
      writeln('Все хорошо!');
      readTimer := new Timer(100,executeActions);
      readTimer.Start;
    end;
end;

function MyRobot.Disconnect : boolean;
begin
  brick.Disconnect;
  Result := true;
end;

procedure MyRobot.Stop;
begin
  if MotA <> nil then
    MotA.Stop;
  if MotB <> nil then
    MotB.Stop;
  if MotC <> nil then
    MotC.Stop;
end;

procedure MyRobot.executeActions;
begin
  for var i := 0 to Length(handlers) do
    handlers[i](self);
end;

procedure MyRobot.setAction(v: RoboProc);    //  добавление обработчика
begin
  SetLength(handlers,Length(handlers)+1);
  handlers[Length(handlers)-1] := v;
end;

{procedure MyRobot.addMotorA(m : RoboMotor);
begin
  MotA := m;
  brick.MotorA := NxtMotor.Create();
  brick.MotorA.PollInterval := 50;
  m.motor := brick.MotorA;
  m.brick := brick;
end;}

function MyRobot.getMotorA : RoboMotor;
begin
  if MotA = nil then
    begin
      MotA := RoboMotor.Create();
      brick.MotorA := MotA;
      brick.MotorA.PollInterval := 50;
      brick.MotorA.Coast;
      brick.MotorA.ResetMotorPosition(false);
      (brick.MotorA as Robomotor).SetBrick(brick);
      (brick.MotorA as Robomotor).SetPort(NxtMotorPort.PortA);
    end;
  Result := MotA;
end;

{procedure MyRobot.addMotorB(m : RoboMotor);
begin
  MotB := m;
  brick.MotorB := NxtMotor.Create();
  brick.MotorB.PollInterval := 50;
  m.motor := brick.MotorB;
  m.brick := brick;
end;}

function MyRobot.getMotorB : RoboMotor;
begin
  if MotB = nil then
    begin
      MotB := RoboMotor.Create();
      brick.MotorB := MotB;
      brick.MotorB.PollInterval := 50;
      brick.MotorB.ResetMotorPosition(false);
      (brick.MotorB as Robomotor).SetBrick(brick);
      (brick.MotorB as Robomotor).SetPort(NxtMotorPort.PortB);
    end;
  Result := MotB;
end;

{procedure MyRobot.addMotorC(m : RoboMotor);
begin
  MotC := m;
  brick.MotorC := NxtMotor.Create();
  brick.MotorC.PollInterval := 50;
  brick.MotorC.ResetMotorPosition(false);
  m.motor := brick.MotorC;
  m.brick := brick;
end;}

function MyRobot.getMotorC : RoboMotor;
begin
  if MotC = nil then
    begin
      MotC := RoboMotor.Create();
      brick.MotorC := MotC;
      brick.MotorC.PollInterval := 50;
      brick.MotorC.ResetMotorPosition(false);
      (brick.MotorC as Robomotor).SetBrick(brick);
      (brick.MotorC as Robomotor).SetPort(NxtMotorPort.PortC);
    end;
  Result := MotC;
end;

{function MyRobot.GetMotorState : string;
begin
  Result := 'Состояние мотора : ';
  if brick.MotorB.TachoCount.HasValue then 
    Result := Result + IntToStr(brick.MotorB.TachoCount.Value)
  else
    Result := Result + 'значение отсутвует';

  {if ((brick.MotorB) as RoboMotor).IsRunning then 
    Result := Result + ' работаем'
  else
    Result := Result + ' молчим';}

  
{  if brick.MotorB.
    Result += IntToStr(brick.MotorB.TachoCount.Value)+'\n'
  else
    Result += 'значение отсутвует\n';
  
end;}


//  Запоминание сенсора для последующей инициализации
procedure MyRobot.AddSensor(sType : sensorType; sPort : integer);
begin
  sns[sPort] := sType;
end;

procedure MyRobot.InitSensors;
begin
  for var sPort:=1 to 4 do
  case sns[sPort] of
    sUltrasonic : 
          case sPort of
            1 : begin brick.Sensor1 := new NxtUltrasonicSensor(); brick.Sensor1.PollInterval := 50; sns[1] := sUltrasonic end;
            2 : begin brick.Sensor2 := new NxtUltrasonicSensor(); brick.Sensor2.PollInterval := 50; sns[2] := sUltrasonic  end;
            3 : begin brick.Sensor3 := new NxtUltrasonicSensor(); brick.Sensor3.PollInterval := 50; sns[3] := sUltrasonic  end;
            4 : begin brick.Sensor4 := new NxtUltrasonicSensor(); brick.Sensor4.PollInterval := 500; sns[4] := sUltrasonic end;
          end;
    sLight : 
          case sPort of
            1 : begin brick.Sensor1 := new Nxt2ColorSensor; Nxt2ColorSensor(brick.Sensor1).SetLightSensorMode(Nxt2Color.Red); brick.Sensor1.PollInterval := 100; sns[1] := sLight end;
            2 : begin brick.Sensor2 := new Nxt2ColorSensor; Nxt2ColorSensor(brick.Sensor2).SetLightSensorMode(Nxt2Color.Red); brick.Sensor2.PollInterval := 100; sns[2] := sLight end;
            3 : begin brick.Sensor3 := new Nxt2ColorSensor; Nxt2ColorSensor(brick.Sensor3).SetLightSensorMode(Nxt2Color.Red); brick.Sensor3.PollInterval := 100; sns[3] := sLight end;
            4 : begin brick.Sensor4 := new Nxt2ColorSensor; Nxt2ColorSensor(brick.Sensor4).SetLightSensorMode(Nxt2Color.Red); brick.Sensor4.PollInterval := 100; sns[4] := sLight end;
          end;
    sColor : 
          case sPort of
            1 : begin brick.Sensor1 := new Nxt2ColorSensor; Nxt2ColorSensor(brick.Sensor1).SetColorDetectorMode(); brick.Sensor1.PollInterval := 100; sns[1] := sColor end;
            2 : begin brick.Sensor2 := new Nxt2ColorSensor; Nxt2ColorSensor(brick.Sensor2).SetColorDetectorMode(); brick.Sensor2.PollInterval := 100; sns[2] := sColor end;
            3 : begin brick.Sensor3 := new Nxt2ColorSensor; Nxt2ColorSensor(brick.Sensor3).SetColorDetectorMode(); brick.Sensor3.PollInterval := 100; sns[3] := sColor end;
            4 : begin brick.Sensor4 := new Nxt2ColorSensor; Nxt2ColorSensor(brick.Sensor4).SetColorDetectorMode(); brick.Sensor4.PollInterval := 100; sns[4] := sColor end;
          end;          
  end;
end;


function MyRobot.getDistance : byte;
begin
  if sns[4] = sUltrasonic then
    begin
      if NxtUltrasonicSensor(brick.Sensor4).DistanceCm.HasValue then
        Result := byte(NxtUltrasonicSensor(brick.Sensor4).DistanceCm)
      else
        Result := 0;
      exit;
    end;
  if sns[2] = sUltrasonic then
    begin
      Result := byte(NxtUltrasonicSensor(brick.Sensor2).DistanceCm);
      exit;
    end;
  if sns[3] = sUltrasonic then
    begin
      Result := byte(NxtUltrasonicSensor(brick.Sensor3).DistanceCm);
      exit;
    end;
  if sns[1] = sUltrasonic then
    begin
      Result := byte(NxtUltrasonicSensor(brick.Sensor1).DistanceCm);
      exit;
    end;
  Result := 0;
end;

function MyRobot.getColor : string;
begin
  if sns[3] = sColor then
    begin
      Result := Nxt2ColorSensor(brick.Sensor3).Color.ToString;
      exit;
    end;
  if sns[4] = sColor then
    begin
      Result := Nxt2ColorSensor(brick.Sensor4).Color.ToString;
      exit;
    end;
  if sns[1] = sColor then
    begin
      Result := Nxt2ColorSensor(brick.Sensor1).Color.ToString;
      exit;
    end;
  if sns[2] = sColor then
    begin
      Result := Nxt2ColorSensor(brick.Sensor2).Color.ToString;
      exit;
    end;
  Result := 'No sensor!';  
end;

function MyRobot.getLight : byte;
begin
  if sns[3] = sLight then
    begin
      Result := byte(Nxt2ColorSensor(brick.Sensor3).Intensity.Value);
      exit;
    end;
  if sns[4] = sLight then
    begin
      Result := byte(Nxt2ColorSensor(brick.Sensor4).Intensity.Value);
      exit;
    end;
  if sns[1] = sLight then
    begin
      Result := byte(Nxt2ColorSensor(brick.Sensor1).Intensity.Value);
      exit;
    end;
  if sns[2] = sLight then
    begin
      Result := byte(Nxt2ColorSensor(brick.Sensor2).Intensity.Value);
      exit;
    end;
  Result := 0;
end;

{procedure MyRobot.AddMotor(mPort : motorPort);
begin
  case mPort of
    PortA : begin brick.MotorA := NxtMotor.Create;
                  motA := new RoboMotor;
                  motA.motor := brick.MotorA;
                  brick.MotorA.PollInterval := 50; end;
    PortB : begin brick.MotorB := NxtMotor.Create;
                  motB := new RoboMotor;
                  motB.motor := brick.MotorB;
                  brick.MotorB.PollInterval := 50; end;
    PortC : begin brick.MotorC := NxtMotor.Create;
                  motC := new RoboMotor;
                  motC.motor := brick.MotorC;
                  brick.MotorC.PollInterval := 50; end;
  end;
end;}

procedure MyRobot.SetInterval(interval : integer);
begin
  readTimer.Interval := interval;
end;

end.

{

procedure touchSensor_OnPolled(polledItem: NxtPollable);
begin
  touchSensor := NxtTouchSensor(polledItem);
  // необходимо преобразовывать к boolean так как touchSensor.IsPressed возвращает Nullable<bollean>
  isPressed := boolean(touchSensor.IsPressed);
  if (isPressed) then
    Writeln('Touch sensor pressed');
end;

procedure UltrasonicSensor_OnPolled(polledItem: NxtPollable);
begin
  UltrasonicSensor := NxtUltrasonicSensor(polledItem);
  // необходимо преобразовывать к byte так как UltrasonicSensor.DistanceCm возвращает Nullable<byte>
  distanse := byte(UltrasonicSensor.DistanceCm);
  //WriteLn(distanse);
end;

begin
  isPressed:=false;
 
  // Создаем touch sensor.
  touchSensor := new NxtTouchSensor();
  
  // Создаем Ultrasonic sensor.
  UltrasonicSensor := new NxtUltrasonicSensor();
  
  // Присоединяем моторы к порту А и С на NXT.
  brick.MotorA := new NxtMotor();
  brick.MotorB := new NxtMotor();
  brick.MotorC := new NxtMotor();
  
  // присоединяем touchSensor к порту 1.
  brick.Sensor1 := touchSensor;
  
  // Присоединяем Ультразвуковой сенсор к порту 4.
  brick.Sensor4 := UltrasonicSensor;
  
  // Устанавливаем интервал опроса сенсоров 50 милисекунд.
  touchSensor.PollInterval := 50;
  UltrasonicSensor.PollInterval := 50;
  
  // Обрабатываем событие опроса сенсоров.
  touchSensor.OnPolled += touchSensor_OnPolled;
  UltrasonicSensor.OnPolled += UltrasonicSensor_OnPolled;
  // Соединяемся NXT.
  brick.Connect();
  // Ждем для обработки событий
  Writeln('Press any key to stop.');
  sleep(3000);
  //for var i:=1 to 100 do
     writeln(distanse);
  readln();
  // Запускаем моторы с мощьностью 75%, на 1600 градксов.
  brick.MotorA.Run(75, 1600);
  brick.MotorC.Run(75, 1600);
  
  // Отсоединяемся от  NXT.
  brick.Disconnect();
end.}
