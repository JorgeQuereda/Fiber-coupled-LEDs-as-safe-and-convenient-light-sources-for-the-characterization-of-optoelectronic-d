%% Diode on-off ramp

%% initialize equipment
equipment.SM=[]; %Keithley 2450 Source Meter
equipment.TM=[]; %Tenma Voltage Source
 
% initialize communications
try equipment.SM = visa('ni', 'USB0::0x05E6::0x2450::S/N::INSTR'); 
fopen(equipment.SM); 
disp('SM 1 FOUND')
catch
equipment.SM = []; 
disp('SM 1 ERROR')
end
try equipment.TM = serial('COM1'); 
fopen(equipment.TM(1)); 
disp('TM 1 FOUND')
catch
equipment.TM = [];
disp('TM 1 ERROR')
end

%% Set measurement parameters
Vsd=1;
V_diode=[0 0.05 0.1 0.25 0.5 0.75 1:0.5:5];
T_init=2;
T_on=2;
T_off=30;

%% Ramp Vsd to measurement value
V0=str2num(query(equipment.SM,'MEAS:VOLT?'));
stepsize=0.01;
if V0>Vsd
    stepsize=-abs(stepsize);
elseif V0<Vsd
    stepsize=abs(stepsize);
end
Vramp=[V0:stepsize:Vsd Vsd]; %define ramp
disp(['ramping sourcementer to V = ',num2str(Vsd)])
for n=1:length(Vramp) % do ramp
    message=['SOUR:VOLT ' num2str(Vramp(n))];
    fprintf(equipment.SM,message);
end
disp('ramp done')

%% Do Measurement
for i=1:length(V_diode)
    clear I t
    ind=1;
    tic
    t0=toc;
    t1=toc;
    hplot(i)=plot(NaN,NaN);
    hold on

    % set Tenma to 0 V
    V=0;
    message = strcat('VSET',num2str(1),': ',num2str(V));
    fprintf(equipment.TM, '%s', message);
    
    % measure OFF current
    while t1-t0<T_init
        I(ind)=str2num(query(equipment.SM,'MEAS:CURR?'));
        t(ind)=toc;
        t1=t(ind);
        ind=ind+1;
        set(hplot(i),'xdata',t,'ydata',I); drawnow;
    end
    
    % set Tenma to next voltage value
    V=V_diode(i);
    message = strcat('VSET',num2str(1),': ',num2str(V));
    fprintf(equipment.TM, '%s', message);
    
    % measure ON current
    while t1-t0<T_on+T_init
        I(ind)=str2num(query(equipment.SM,'MEAS:CURR?'));
        t(ind)=toc;
        t1=t(ind);
        ind=ind+1;
        set(hplot(i),'xdata',t,'ydata',I); drawnow;
    end
    
    % set Tenma to 0 V
    V=0;
    message = strcat('VSET',num2str(1),': ',num2str(V));
    fprintf(equipment.TM, '%s', message);
    
    % wait for recovery
    while t1-t0<T_off+T_on+T_init
        I(ind)=str2num(query(equipment.SM,'MEAS:CURR?'));
        t(ind)=toc;
        t1=t(ind);
        ind=ind+1;
        set(hplot(i),'xdata',t,'ydata',I); drawnow;
    end
end
legend(num2str([V_diode(:)]))
