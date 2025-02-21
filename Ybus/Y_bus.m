clc;
filename = 'line_data.xlsx';
line_data = readmatrix(filename);
Qmin = 0;
Qmax = 0.35;

n = length(unique([line_data(:, 1); line_data(:, 2)]));
Ybus = zeros(n,n);

for k = 1:size(line_data,1)
    from_bus = line_data(k,1);
    to_bus = line_data(k,2);
    R = line_data(k,3);
    X = line_data(k,4);
    
    %B = line_data(k,5);
    %G = line_data(k,6);
    
    Z = R + 1i*X;
    Y = 1/Z;
    %Y_shunt =G + 1i*(B);

    Ybus(from_bus, to_bus) = Ybus(from_bus, to_bus) - Y;
    Ybus(to_bus, from_bus) = Ybus(to_bus, from_bus) - Y;
    Ybus(from_bus, from_bus) = Ybus(from_bus, from_bus) +Y; %+Y_shunt%
    Ybus(to_bus, to_bus) = Ybus(to_bus, to_bus) +Y; %+Y_shunt%

end
disp('Y-bus Matrix: ');
disp(Ybus)


%Gauss Seidel method for load flow analysis%

filename = 'bus_data.xlsx';
bus_data = readmatrix(filename);

slack_bus = find(bus_data(:, 2)==1);
PQ_buses = find(bus_data(:, 2) == 2);
PV_buses = find(bus_data(:, 2) == 3);

V = ones(n ,1);

P_load = bus_data(: ,5);
Q_load = bus_data(:, 6);
P_gen = bus_data(:, 7);
Q_gen = bus_data(:, 8);

P_spec = P_gen - P_load;
Q_spec = Q_gen - Q_load;

max_iter = 7;
tolerance = 1e-6; 

for iter = 1:max_iter
    V_prev = V;
    
    for i = 1:n
        if ismember(i, slack_bus)
            continue; % Skip slack bus
        end
        
        % Summation term
        sum_YV = 0;
        for j = 1:n
            if j ~= i
                sum_YV = sum_YV + Ybus(i, j) * V(j);
            end
        end
        
        % Update voltage for PQ and PV buses
        if ismember(i, PQ_buses)
            V(i) = (1 / Ybus(i, i)) * ((P_spec(i) - 1i * Q_spec(i)) / conj(V(i)) - sum_YV);
        elseif ismember(i, PV_buses)
            Q_calc_i = -imag(conj(V(i)) * sum(Ybus(i, :) .* V.'));
            if Q_calc_i < Qmin(i)
                Q_calc_i = Qmin(i);
            elseif Q_calc_i > Qmax(i)
                Q_calc_i = Qmax(i);
            end
            V_temp = (1 / Ybus(i, i)) * ((P_spec(i) - 1i * Q_calc_i) / conj(V(i)) - sum_YV);
            V(i) = abs(bus_data(i, 3)) * exp(1i * angle(V_temp)); % Maintain specified voltage magnitude
        end
    end
    if max(abs(V - V_prev)) < tolerance
        break;
    end
end
P_calc = zeros(n ,1);
Q_calc = zeros(n ,1);

for i = 1:n
    for j = 1:n
        P_calc(i) = P_calc(i) + abs(V(i)) * abs(V(j)) * abs(Ybus(i, j)) * cos(angle(Ybus(i, j)) + angle(V(j)) - angle(V(i)));
        Q_calc(i) = Q_calc(i) - abs(V(i)) * abs(V(j)) * abs(Ybus(i, j)) * sin(angle(Ybus(i, j)) + angle(V(j)) - angle(V(i)));
    end
end

disp('Bus Voltages (in pu):');
for i = 1:n
    fprintf('Bus %d: |V| = %.4f pu, Angle = %.2f degrees\n', i, abs(V(i)), rad2deg(angle(V(i))));
end
fprintf('\n');

disp('Power Flow Results:');
for i = 1:n 
     fprintf('Bus %d: P = %.4f pu, Q = %.4f pu\n', i, P_calc(i), Q_calc(i));
end
fprintf('\n');
	



