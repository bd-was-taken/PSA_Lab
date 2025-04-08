clc;
clear all;
close all;

% MATLAB Code for Example 7.2 Load Flow Analysis

% --- Input Data ---
% Base MVA
S_base = 100;

% Bus Data
bus_data = [
    1, 1.05, 0, 0, 50, 30;   % Bus 1 (Slack) - V, delta, Pl, Ql, Pg, Qg
    2, 1.00, 305.6, 140.2, 50, 30; % Bus 2 - Pl, Ql, Pg, Qg
    3, 1.00, 138.6, 45.2, 0, 0;   % Bus 3 - Pl, Ql, Pg, Qg
];

% Line Data
line_data = [
    1, 2, 0.02, 0.04; % From Bus, To Bus, R, X
    1, 3, 0.01, 0.03;
    2, 3, 0.0125, 0.025;
];

% --- Step 1: Initial Computations ---
% Convert Loads to Per-Unit
Pl_pu = bus_data(:, 3) / S_base;
Ql_pu = bus_data(:, 4) / S_base;

% Convert Generation to Per-Unit
Pg_pu = bus_data(:, 5) / S_base;
Qg_pu = bus_data(:, 6) / S_base;

% Compute Net Injected Power
P_net = Pg_pu - Pl_pu;
Q_net = Qg_pu - Ql_pu;

% --- Step 2: Form Y_bus Matrix ---
num_buses = length(bus_data(:, 1));
Y_bus = zeros(num_buses);

% Calculate Admittances
for i = 1:length(line_data(:, 1))
    Z = line_data(i, 3) + 1j * line_data(i, 4);
    Y = 1 / Z;
    from_bus = line_data(i, 1);
    to_bus = line_data(i, 2);

    Y_bus(from_bus, from_bus) = Y_bus(from_bus, from_bus) + Y;
    Y_bus(to_bus, to_bus) = Y_bus(to_bus, to_bus) + Y;
    Y_bus(from_bus, to_bus) = Y_bus(from_bus, to_bus) - Y;
    Y_bus(to_bus, from_bus) = Y_bus(to_bus, from_bus) - Y;
end

% Convert Y_bus to Polar Form
Y_mag = abs(Y_bus); % Magnitude
Y_ang = angle(Y_bus); % Angle

% Display Y_bus (for verification)
disp('Y_bus Matrix (Polar Form):');
for i = 1:num_buses
    for j = 1:num_buses
        fprintf('%.2f /_ %.2f  ', Y_mag(i, j), rad2deg(Y_ang(i, j)));
    end
    fprintf('\n');
end

% --- Step 3: Newton-Raphson Iteration ---
% Initialize Voltage Magnitudes and Angles
V_mag = bus_data(:, 2);
V_ang = zeros(num_buses, 1); % Initial angles are 0
V_ang(1) = deg2rad(0); % Slack bus angle is 0

% Define known values
V1_mag = V_mag(1);
delta1 = V_ang(1);

% Bus 2
Y21_mag = Y_mag(2, 1);
theta21 = Y_ang(2, 1);
Y22_mag = Y_mag(2, 2);
theta22 = Y_ang(2, 2);
Y23_mag = Y_mag(2, 3);
theta23 = Y_ang(2, 3);

% Bus 3
Y31_mag = Y_mag(3, 1);
theta31 = Y_ang(3, 1);
Y32_mag = Y_mag(3, 2);
theta32 = Y_ang(3, 2);
Y33_mag = Y_mag(3, 3);
theta33 = Y_ang(3, 3);

V2_mag = V_mag(2); % Initial guess = 1
V3_mag = V_mag(3); % Initial guess = 1
delta2 = V_ang(2); % Initial guess = 0
delta3 = V_ang(3); % Initial guess = 0

% Calculate Jacobian Elements (First Iteration)
dP2_dD2 = V2_mag * V1_mag * Y21_mag * sin(theta21 - delta2 + delta1) + V2_mag * V3_mag * Y23_mag * sin(theta23 - delta2 + delta3);
dP2_dD3 = -V2_mag * V3_mag * Y23_mag * sin(theta23 - delta2 + delta3);
dP3_dD2 = -V3_mag * V2_mag * Y32_mag * sin(theta32 - delta3 + delta2);
dP3_dD3 = V3_mag * V1_mag * Y31_mag * sin(theta31 - delta3 + delta1) + V3_mag * V2_mag * Y32_mag * sin(theta32 - delta3 + delta2);

dQ2_dV2 = -V1_mag * Y21_mag * sin(theta21 - delta2 + delta1) - 2 * V2_mag * Y22_mag * sin(theta22) - V3_mag * Y23_mag * sin(theta23 - delta2 + delta3);
dQ3_dV3 = -V1_mag * Y31_mag * sin(theta31 - delta3 + delta1) - V2_mag * Y32_mag * sin(theta32 - delta3 + delta2) - 2 * V3_mag * Y33_mag * sin(theta33);
dQ2_dV3 = -V2_mag * Y23_mag * sin(theta23 - delta2 + delta3);
dQ3_dV2 = -V3_mag * Y32_mag * sin(theta32 - delta3 + delta2);

% Jacobian Matrices
J1 = [dP2_dD2, dP2_dD3; dP3_dD2, dP3_dD3]; % Delta-Delta Jacobian
J4 = [dQ2_dV2, dQ2_dV3; dQ3_dV2, dQ3_dV3]; % V-V Jacobian

% Calculate Power Mismatches (First Iteration)
P2_calc = V2_mag * V1_mag * Y21_mag * cos(theta21 - delta2 + delta1) + V2_mag^2 * Y22_mag * cos(theta22) + V2_mag * V3_mag * Y23_mag * cos(theta23 - delta2 + delta3);
P3_calc = V3_mag * V1_mag * Y31_mag * cos(theta31 - delta3 + delta1) + V3_mag * V2_mag * Y32_mag * cos(theta32 - delta3 + delta2) + V3_mag^2 * Y33_mag * cos(theta33);
Q2_calc = -V2_mag * V1_mag * Y21_mag * sin(theta21 - delta2 + delta1) - V2_mag^2 * Y22_mag * sin(theta22) - V2_mag * V3_mag * Y23_mag * sin(theta23 - delta2 + delta3);
Q3_calc = -V3_mag * V1_mag * Y31_mag * sin(theta31 - delta3 + delta1) - V3_mag * V2_mag * Y32_mag * sin(theta32 - delta3 + delta2) - V3_mag^2 * Y33_mag * sin(theta33);

dP2 = P_net(2) - P2_calc;
dP3 = P_net(3) - P3_calc;
dQ2 = Q_net(2) - Q2_calc;
dQ3 = Q_net(3) - Q3_calc;

% Solve for Corrections
dDelta = J1 \ [dP2; dP3];
dV_mag = J4 \ [dQ2; dQ3];

% Update Voltage Angles and Magnitudes
delta2_new = delta2 + dDelta(1);
delta3_new = delta3 + dDelta(2);
V2_mag_new = V2_mag + dV_mag(1);
V3_mag_new = V3_mag + dV_mag(2);

% Convert angles to degrees
delta2_new_deg = rad2deg(delta2_new);
delta3_new_deg = rad2deg(delta3_new);

% --- Display Results ---
fprintf('\n--- Load Flow Analysis Results (First Iteration) ---\n');
fprintf('\nBus Voltages:\n');
fprintf('Bus | Voltage (pu) | Angle (degrees)\n');
fprintf('----|--------------|-----------------\n');
fprintf(' 1  | %8.4f     | %9.4f\n', V1_mag, rad2deg(delta1));
fprintf(' 2  | %8.4f     | %9.4f\n', V2_mag_new, delta2_new_deg);
fprintf(' 3  | %8.4f     | %9.4f\n', V3_mag_new, delta3_new_deg);

% MATLAB Code for Example 7.2 Load Flow Analysis
% ... (all the code from before, up to the Jacobian calculation)

% Calculate Jacobian Elements (First Iteration)
dP2_dD2 = V2_mag * V1_mag * Y21_mag * sin(theta21 - delta2 + delta1) + V2_mag * V3_mag * Y23_mag * sin(theta23 - delta2 + delta3);
dP2_dD3 = -V2_mag * V3_mag * Y23_mag * sin(theta23 - delta2 + delta3);
dP2_dV2 = V2_mag * V1_mag * Y21_mag * cos(theta21 - delta2 + delta1) + 2*V2_mag * Y22_mag * cos(theta22) + V2_mag * V3_mag * cos(theta23 - delta2 + delta3) ;
dP2_dV3 = V2_mag * Y23_mag * cos(theta23 - delta2 + delta3);

dP3_dD2 = -V3_mag * V2_mag * Y32_mag * sin(theta32 - delta3 + delta2);
dP3_dD3 = V3_mag * V1_mag * Y31_mag * sin(theta31 - delta3 + delta1) + V3_mag * V2_mag * Y32_mag * sin(theta32 - delta3 + delta2);
dP3_dV2 = V3_mag * Y32_mag * cos(theta32 - delta3 + delta2);
dP3_dV3 = V3_mag * V1_mag * cos(theta31 - delta3 + delta1) + 2*V3_mag * Y33_mag * cos(theta33) + V3_mag * V2_mag * cos(theta32 - delta3 + delta2);

dQ2_dD2 = -V2_mag * V1_mag * Y21_mag * cos(theta21 - delta2 + delta1) + V2_mag * V3_mag * Y23_mag * cos(theta23 - delta2 + delta3);
dQ2_dD3 = V2_mag * V3_mag * Y23_mag * cos(theta23 - delta2 + delta3);
dQ2_dV2 = -V1_mag * Y21_mag * sin(theta21 - delta2 + delta1) - 2 * V2_mag * Y22_mag * sin(theta22) - V3_mag * Y23_mag * sin(theta23 - delta2 + delta3);
dQ2_dV3 = -V2_mag * Y23_mag * sin(theta23 - delta2 + delta3);

dQ3_dD2 = V3_mag * V2_mag * Y32_mag * cos(theta32 - delta3 + delta2);
dQ3_dD3 = -V3_mag * V1_mag * Y31_mag * cos(theta31 - delta3 + delta1) - V3_mag * V2_mag * Y32_mag * cos(theta32 - delta3 + delta2);
dQ3_dV2 = -V3_mag * Y32_mag * sin(theta32 - delta3 + delta2);
dQ3_dV3 = -V1_mag * Y31_mag * sin(theta31 - delta3 + delta1) - V2_mag * Y32_mag * sin(theta32 - delta3 + delta2) - 2 * V3_mag * Y33_mag * sin(theta33);

% Jacobian Matrices
J1 = [dP2_dD2, dP2_dD3; dP3_dD2, dP3_dD3]; % Delta-Delta Jacobian
J2 = [dP2_dV2, dP2_dV3; dP3_dV2, dP3_dV3]; % Delta-V Jacobian
J3 = [dQ2_dD2, dQ2_dD3; dQ3_dD2, dQ3_dD3]; % dQ/dDelta Jacobian
J4 = [dQ2_dV2, dQ2_dV3; dQ3_dV2, dQ3_dV3]; % dQ/dV Jacobian

% --- Display Jacobian Matrices ---
fprintf('\n--- Jacobian Matrix J1 (dP/dDelta) ---\n');
disp(J1);

fprintf('\n--- Jacobian Matrix J2 (dP/dV) ---\n');
disp(J2);

fprintf('\n--- Jacobian Matrix J3 (dQ/dDelta) ---\n');
disp(J3);

fprintf('\n--- Jacobian Matrix J4 (dQ/dV) ---\n');
disp(J4);

% ... (rest of the code)
