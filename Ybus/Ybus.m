filename = 'data.xlsx';
line_date = readmatrix(filename);

n = max(max(line_data(:,1:2)));
Ybus = zeros(n,n)

for k = 1:size(line_data,1)
    from_bus = line_data(k,1);
    to_bus = line_data(k,2);
    R = line_data(k,3);
    X = line_data(k,4);
    B = line_data(k,5);

    Z = R + 1i*X;
    Y = 1/Z;
    Y_shunt = 1i*B;

    Ybus(from_bus, to_bus) = Ybus(from_bus, to_bus) - Y;
    Ybus(to_bus, from_bus) = Ybus(to_bus, from_bus) - Y;
    Ybus(from_bus, to_bus) = Ybus(from_bus, to_bus) +Y +Y_shunt;
    Ybus(to_bus, from_bus) = Ybus(to_bus, from_bus) +Y +Y_shunt;

end
disp('Y-bus Matrix: ');
disp(Ybus)