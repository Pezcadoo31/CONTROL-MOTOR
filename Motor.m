clearvars
close all

try
    % Configuración del puerto serial
    pserial = serialport('COM3', 2000000);  % Ajusta el puerto según sea necesario
    pserial.Timeout = 2;
    configureTerminator(pserial, "CR/LF");
    flush(pserial);

    % Parámetros
    NumSamples = 10000;  % Número de muestras para reservar memoria
    TotalTime = 10;      % Tiempo total en segundos
    T = 0.01;            % Periodo de muestreo

    % Parámetros adicionales
    Au = 0.18;           % Amplitud de la señal
    w = 0.1 * (2 * pi);  % Frecuencia angular
    uoff = 0.32;         % Desplazamiento

    % Reserva memoria
    U = zeros(1, NumSamples);
    W = zeros(1, NumSamples);
    tReal = zeros(1, NumSamples);
    desired = zeros(1, NumSamples);  % Vector para almacenar la señal deseada

    % Calcular la señal deseada con los parámetros
    for i = 1:NumSamples
        desired(i) =  5; % Au*sin(w* T) + uoff;
    end

    % Parámetros del PID
    Kp = 0.001918509;%0.08522727;
    Ki = 0.252;%0.18;
    Kd = 0;

    % Crear un temporizador
    tobj = timer;
    tobj.UserData = struct('Ie', 0, 'e_1', 0, 'contador', 0, ...
        'U', U, 'W', W, 'tReal', tReal, 'desired', desired, ...
        'pserial', pserial, 'startTime', tic, ...
        'Kp', Kp, 'Ki', Ki, 'Kd', Kd, 'T', T, ...
        'TotalTime', TotalTime);

    tobj.TimerFcn = @(~,~) timerCallback(tobj);
    tobj.StopFcn = @(~,~) disp('Adquisición de datos finalizada.');
    tobj.Period = T;
    tobj.ExecutionMode = 'fixedRate';
    tobj.TasksToExecute = NumSamples;

    % Iniciar el temporizador
    start(tobj)

    % Esperar a que finalice el temporizador
    wait(tobj)

    % Guarda los datos finales y elimina ceros no utilizados
    actualLength = tobj.UserData.contador;
    tReal = tobj.UserData.tReal(1:actualLength);
    U = tobj.UserData.U(1:actualLength);
    W = tobj.UserData.W(1:actualLength);
    desired = tobj.UserData.desired(1:actualLength);

    % Graficar resultados
    figure;
    plot(tReal, desired, '--k', 'DisplayName', 'Valor Deseado');
    hold on;
    plot(tReal, U, '-b', 'DisplayName', 'Control Action (U)');
    plot(tReal, W, '-r', 'DisplayName', 'Resultado (W)');
    title('Señal deseada vs Acción de control vs Resultado');
    xlabel('Tiempo (s)');
    ylabel('Valor');
    legend('show');
    grid on;

    % Cerrar puerto serial
    clear pserial
    delete(tobj)

catch ME
    disp("Error en la ejecución:")
    disp(ME.message)
end

% Función de callback para el temporizador
function timerCallback(tobj)
% Índice de muestra
i = tobj.UserData.contador + 1;
tobj.UserData.contador = i;

% Tiempo actual
currentTime = toc(tobj.UserData.startTime);
tobj.UserData.tReal(i) = currentTime;

% Señal deseada
desired = tobj.UserData.desired(i);

% Leer respuesta del actuador
respuesta = 0;
if tobj.UserData.pserial.NumBytesAvailable > 0
    respuesta = str2double(readline(tobj.UserData.pserial));
end
tobj.UserData.W(i) = respuesta;

% Calcular error
e = desired - respuesta;

% PID: calcular la acción de control
Kp = tobj.UserData.Kp;
Ki = tobj.UserData.Ki;
Kd = tobj.UserData.Kd;
T = tobj.UserData.T;
Ie = tobj.UserData.Ie;
e_1 = tobj.UserData.e_1;

Ie = Ie + (e + e_1) * Ki * T / 2;
De = (e - e_1) / T;
u = Kp * e + Ie + Kd * De;

% Saturación de la salida
u = max(min(u, 1), 0);

% Enviar la acción de control al actuador
writeline(tobj.UserData.pserial, num2str(u, '%.4f'));

% Guardar los valores
tobj.UserData.U(i) = u;
tobj.UserData.Ie = Ie;
tobj.UserData.e_1 = e;

% Detener el temporizador si se alcanza el tiempo total
if currentTime >= tobj.UserData.TotalTime
    stop(tobj);
end
end

% --- Cálculos de desempeño y errores integrales --- %

% Calcular el valor final
Yfin = mean(W(end-30:end)); % Promedio de los últimos 30 valores de W para estimar el valor final
disp(['El valor final es = ', num2str(Yfin)])

% Error en estado estacionario
ref = desired(end); % Utilizamos la última referencia como referencia de estado estacionario
Eee = ref - Yfin;
disp(['El error en estado estacionario es = ', num2str(Eee)])

% Tiempo de establecimiento (2%)
Elim = 0.02 * abs(Yfin); % Definimos el límite del 2% para el cálculo del tiempo de establecimiento
ts = NaN; % Inicializamos el tiempo de establecimiento como NaN

% Busca el último punto en el que la salida se mantiene dentro del límite del 2%
for i = 1:length(tReal)
    if abs(W(i) - Yfin) > Elim
        ts = tReal(i); % Guardamos el tiempo de salida del 2%
    end
end

% Si se encontró un tiempo fuera del 2%, incrementamos al siguiente punto
if ~isnan(ts)
    ts = tReal(find(tReal == ts) + 1); % Encuentra el siguiente tiempo
else
    ts = tReal(end); % Si nunca salió del rango, es el tiempo final
end

disp(['El tiempo de establecimiento (Ts) es = ', num2str(ts)])

% Valor pico y tiempo pico
[Ymax, indice] = max(W); % Encuentra el valor máximo de la salida W y su índice
tp = tReal(indice); % Tiempo en que se alcanza el valor máximo
if Ymax > Yfin
    Mp = (Ymax - Yfin) / Yfin; % Calcula el sobreimpulso relativo
else
    Mp = 0; % Si no hay sobreimpulso, es 0
end
disp(['El sobreimpulso (Mp) es = ', num2str(Mp), ', y el tiempo pico (tp) es = ', num2str(tp)])

% Tiempo de crecimiento
tr = NaN; % Inicializamos el tiempo de crecimiento
for i = 1:length(tReal)
    if W(i) >= Yfin
        tr = tReal(i); % Encuentra el primer tiempo en que la salida alcanza el valor final
        break
    end
end
disp(['El tiempo de crecimiento (Tr) es = ', num2str(tr)])

% Integral del error cuadrático (ISE)
R = ref * ones(length(W), 1); % Referencia constante
E = R - W; % Error
ise = 0;
for i = 2:length(W)
    ise = ise + (E(i)^2 + E(i-1)^2) * (tReal(i) - tReal(i-1)) / 2; % Calcula el área bajo la curva del error cuadrático
end
disp(['La integral de error cuadrático (ISE) es = ', num2str(ise)])

% Integral del error absoluto (IAE)
iae = 0;
for i = 2:length(W)
    iae = iae + (abs(E(i)) + abs(E(i-1))) * (tReal(i) - tReal(i-1)) / 2; % Calcula el área bajo la curva del error absoluto
end
disp(['La integral de error absoluto (IAE) es = ', num2str(iae)])

% Integral de tiempo y error cuadrático (ITSE)
itse = 0;
for i = 2:length(W)
    itse = itse + (tReal(i) * E(i)^2 + tReal(i-1) * E(i-1)^2) * (tReal(i) - tReal(i-1)) / 2; % Calcula el error cuadrático ponderado por el tiempo
end
disp(['La integral de tiempo y error cuadrático (ITSE) es = ', num2str(itse)])

% Integral del error en tiempo absoluto (ITAE)
itae = 0;
for i = 2:length(W)
    itae = itae + (tReal(i) * abs(E(i)) + tReal(i-1) * abs(E(i-1))) * (tReal(i) - tReal(i-1)) / 2; % Calcula el error absoluto ponderado por el tiempo
end
disp(['La integral del error en tiempo absoluto (ITAE) es = ', num2str(itae)])

% --- Fin de cálculos de desempeño y errores integrales ---
