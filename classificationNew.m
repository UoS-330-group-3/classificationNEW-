%%
rosshutdown;
%%
% starting Ros thing
%RobwLAN ip
rosinit('172.30.58.203','NodeHost','172.30.58.209','NodeName','/classification');
%home IP
%rosinit('192.168.0.83','NodeHost','192.168.0.14','NodeName','/classification');
% Using the Gauss meter to measure the field strength value then
% Calculate mean using the last x samples.
% Using 200ms sampling rate, wait 20 second for csv to update
PauseTime = 2;
MeasuredSamples = 40;
RosRunning = true;
ID = 0;
%%
MagTaken_Sub = rossubscriber('/MagTaken','std_msgs/Bool');
%MagMove = rospublisher('/MagMove','std_msgs/Bool');
MagPls_Pub = rospublisher('/MagPls','std_msgs/Bool');
MagData_Pub = rospublisher('/MagData','std_msgs/Float32MultiArray');

rosGoSub = rossubscriber('/RunProcess','std_msgs/Int8');
rosGoPub = rospublisher('/RunProcess','std_msgs/Int8');
status = rosmessage('std_msgs/Int8');

status.Data=1;

send(rosGoPub, status);

MagTaken.Data = 1;

while(1)
% % % % %     simulating waiting for prompt from ros that magnet has been released
% % % % %     when ros is implemented here is must wait for input before continuing
% % % % %     prompt = 'Enter anything to read table: \n';
% % % % %     input(prompt,'s');

    %Ros implementation
    

    if MagTaken.Data == 1
        disp("Arm1 Received")
        %ros implementation
        MagPls_msg = rosmessage('std_msgs/Bool');
        MagPls_msg.Data = 1;
        send(MagPls_Pub,MagPls_msg);
        disp("Servo control sent")
        %wauting for magnet to be released
        disp("waiting 5 seconds");
        pause(5);
        disp("after 5 seconds");
        %Increasing ID
        ID=ID+1;
        disp("waiting  15 seconds");
        %waiting 20 seconds for gaussmeter to gather info about the current magnet
        pause(PauseTime); 
        disp("after pause")
        %reading the lagest table of data points from the gaussmeter
        GaussData = readtable("GaussReadings.csv");
        
        %extracting the field strength values from the array
        FieldStrength = table2array(GaussData(:,1));
    
        %calculating the mean of the previous x samples 
        TableSize = length(FieldStrength);
        LatestReadings = FieldStrength((TableSize-MeasuredSamples):TableSize,1);
        absLatestReadigns = abs(LatestReadings);
        AbsMeanValue = mean(absLatestReadigns);
        MeanValue = mean(LatestReadings);
    
        %calculating polarity
        if(MeanValue > 0)
            Polarity = 1;
        else
            Polarity = 0;
        end
    
        %Plotting data to Table
        T = table(ID,AbsMeanValue,MeanValue,Polarity,TableSize,'VariableNames',{'Magnet ID','Abs Mean Value','Mean Value','Polarity','Total Samples'});
        disp(T);
        %data to send through ROS
        MagnetData = [ID AbsMeanValue Polarity];
        writematrix(MagnetData,'MagnetData.csv');
        %ros implementation
        MagData_msg = rosmessage(MagData_Pub);
        MagData_msg.Data = MagnetData;
        send(MagData_Pub,MagData_msg);
    end
    
    
    
    rosStatus = rosGoSub.LatestMessage;
    if rosStatus.Data == 0
        disp("shutting system down");
        break;
    end
    
    MagTaken = receive(MagTaken_Sub);
    
end
