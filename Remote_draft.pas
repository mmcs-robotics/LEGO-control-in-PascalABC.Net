{$reference 'NKH.MindSqualls.dll'}
uses LEGORobot, GraphABC, ABCObjects, NKH.MindSqualls;



var robo : MyRobot;
   Text1, Text2 : TextABC;

procedure ReactOnDistance(rob : MyRobot);
  var dist : integer;
begin
  dist := rob.Distance;
  Text1.Text := 'Дистанция (см) : ' + IntToStr(dist);
  Text2.Text := 'TachoCount A : ' + IntToStr(rob.MotorA.TachoCount);
  //exit;
  if dist>40 then 
    begin
      robo.MotorA.Run(30,60);
      robo.MotorC.Run(30,60);    
    end
  else
  if dist<10 then 
    begin
      robo.MotorA.Run(-30,60);
      robo.MotorC.Run(-30,60);    
    end;
end;

procedure KeyDown(key : integer);
begin
  case key of
  VK_UP : begin //  движение прямо
            robo.MotorA.Run(30,360);
            robo.MotorC.Run(30,360);
          end;
  VK_Right : begin //  поворот направо  
            robo.MotorC.Run(25, 360);
            robo.MotorA.Run(-25, 360);
          end;  
  VK_Left : begin //  поворот налево 
            robo.MotorC.Run(-25, 360);
            robo.MotorA.Run(25, 360);
          end;  
  VK_Down : begin  //  движение назад
            robo.MotorA.Run(-25, 0);
            robo.MotorC.Run(-25, 0);
          end;
  VK_Space : //  остановка
          begin
            robo.Stop; 
            
            //robo.brick.CommLink.Disconnect;
          end;
  VK_Q : begin
        robo.Destroy;
        readln;
        halt;
      end;
  end;
end;

begin
  //Text1 := TextABC.Create(10,10,14,'Дистанция...',clBlack);
  //Text2 := TextABC.Create(10,50,14,'TachoCount...',clBlack);

  //  Создаем робота с указанием номера порта
  robo := new MyRobot;
  //  Создаем моторы
  //  robo.MotorA := RoboMotor.Create();
  //  robo.MotorC := RoboMotor.Create();
  //  Определяем ультразвуковой сенсор
  //robo.AddSensor(sUltrasonic,4);
  //robo.AddSensor(sColor,3);
  
  

  //  Добаляем обработчики событий
  //robo.Action := ReactOnDistance;
  //  Соединение с роботом
  if not robo.Connect(3) then 
    begin
      write('Хьюстон, у нас проблема!');
      exit;
    end;
  // robo.brick.Sensor3 := new Nxt2ColorSensor();
  
  //(robo.brick.Sensor3 as Nxt2ColorSensor).SetColorDetectorMode();
  //(robo.brick.Sensor3 as Nxt2ColorSensor).PollInterval := 500;
  
   
  OnKeyDown := KeyDown;
  Window.Width := 700; Window.Height := 500;
  CenterWindow;
  sleep(100);
  {while true do
    begin
      
      writeln('Цвет : ' + robo.Color);
    end;}


  

  
  for var i:=1 to 1000 do
    begin
      {if (robo.brick.Sensor3 as Nxt2ColorSensor).Color.HasValue then
        writeln(i,' - ',(robo.brick.Sensor3 as Nxt2ColorSensor).Color.ToString())
      else
        writeln(i,' - нет значения!');}
      sleep(1000);
      
    end;
    
  
end.