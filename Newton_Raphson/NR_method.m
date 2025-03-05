clc;
clear;
close all;

%% Load Bus and Line Data from Excel
bus_data = xlsread('bus_data.xlsx');
line_data = xlsread('line_data.xlsx');

% Extract bus information
bus_no = bus_data(:,1);
bus_type = bus_data(:,2);  % 1 = Slack, 2 = PQ, 3 = PV
V_mag = bus_data(:,3);
V_angle = bus_data(:,4);
P_gen = bus_data(:,5);
Q_gen = bus_data(:,6);
P_load = bus_data(:,7);
Q_load = bus_data(:,8);

% Number of buses
n_bus = length(bus_no);
slack_bus = find(bus_type == 1); % Identify slack bus dynamically

%% Initialize Voltages
V_mag(bus_type == 2 & V_mag == 0) = 1.0;  % Ensure initial voltage for PQ buses
V_angle(slack_bus) = 0;  % Slack bus angle is fixed at 0

%% Construct Y-Bus Matrix (Without Charging Admittance)
Ybus = zeros(n_bus, n_bus);
for k = 1:size(line_data,1)
    from = line_data(k,1);
    to   = line_data(k,2);
    R    = line_data(k,3);
    X    = line_data(k,4);
    
    Z = R + 1i*X;
    Y = 1/Z;

    % Off-diagonal elements
    Ybus(from, to) = Ybus(from, to) - Y;
    Ybus(to, from) = Ybus(to, from) - Y;
    
    % Diagonal elements
    Ybus(from, from) = Ybus(from, from) + Y;
    Ybus(to, to) = Ybus(to, to) + Y;
end

%% Newton-Raphson Power Flow Implementation
tol = 1e-6;
max_iter = 10000;
iter = 0;

P_specified = P_gen - P_load;
Q_specified = Q_gen - Q_load;

% Identify PV and PQ buses
PQ_buses = find(bus_type == 2);
PV_buses = find(bus_type == 3);
non_slack_buses = [PQ_buses; PV_buses];

while iter < max_iter
    iter = iter + 1;
    
    % Compute P and Q
    P_calc = zeros(n_bus,1);
    Q_calc = zeros(n_bus,1);
    
    for i = 1:n_bus
        for j = 1:n_bus
            P_calc(i) = P_calc(i) + abs(V_mag(i)) * abs(V_mag(j)) * abs(Ybus(i,j)) * cos(angle(Ybus(i,j)) + V_angle(j) - V_angle(i));
            Q_calc(i) = Q_calc(i) - abs(V_mag(i)) * abs(V_mag(j)) * abs(Ybus(i,j)) * sin(angle(Ybus(i,j)) + V_angle(j) - V_angle(i));
        end
    end
    
    % Compute mismatches (excluding slack bus)
    P_mismatch = P_specified(non_slack_buses) - P_calc(non_slack_buses);
    Q_mismatch = Q_specified(PQ_buses) - Q_calc(PQ_buses); % Only for PQ buses
    mismatch = [P_mismatch; Q_mismatch];
    
    % Check convergence
    if max(abs(mismatch)) < tol
        break;
    end
    
    % Jacobian Calculation
    J = zeros(2*length(non_slack_buses), 2*length(non_slack_buses));
    
    for i = 1:length(non_slack_buses)
        m = non_slack_buses(i);
        for j = 1:length(non_slack_buses)
            n = non_slack_buses(j);
            
            if m == n
                J(i, j) = -Q_calc(m) - abs(V_mag(m))^2 * imag(Ybus(m,m));
                J(i+length(non_slack_buses), j+length(non_slack_buses)) = P_calc(m) - abs(V_mag(m))^2 * real(Ybus(m,m));
            else
                J(i, j) = abs(V_mag(m)) * abs(V_mag(n)) * abs(Ybus(m,n)) * sin(angle(Ybus(m,n)) + V_angle(n) - V_angle(m));
                J(i+length(non_slack_buses), j+length(non_slack_buses)) = -abs(V_mag(m)) * abs(V_mag(n)) * abs(Ybus(m,n)) * cos(angle(Ybus(m,n)) + V_angle(n) - V_angle(m));
            end
        end
    end
    
    % Solve for voltage updates
    delta = J \ mismatch;
    
    % Update voltage angles
    V_angle(non_slack_buses) = V_angle(non_slack_buses) + delta(1:length(non_slack_buses));
    
    % Update voltage magnitudes (only PQ buses)
    V_mag(PQ_buses) = max(0.9, min(1.1, V_mag(PQ_buses) + delta(length(non_slack_buses)+1:end)));
    
   % fprintf('Iteration %d, Max Mismatch: %f\n', iter, max(abs(mismatch)));
end

% Display Results
disp('Final Voltage Magnitudes:');
disp(V_mag);
disp('Final Voltage Angles (Degrees):');
disp(rad2deg(V_angle));
