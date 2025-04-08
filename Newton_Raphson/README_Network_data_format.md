Bus Data to be entered in this format:
(already present in the code)

bus_data = [
    1, 1.05, 0, 0, 50, 30;            % Bus 1 (Slack) - V, delta, Pl, Ql, Pg, Qg
    2, 1.00, 305.6, 140.2, 50, 30;    % Bus 2 - Pl, Ql, Pg, Qg
    3, 1.00, 138.6, 45.2, 0, 0;       % Bus 3 - Pl, Ql, Pg, Qg
];


Line Data to be entered in this format:
(already present in the code)

line_data = [
    1, 2, 0.02, 0.04;          % From Bus, To Bus, R, X
    1, 3, 0.01, 0.03;
    2, 3, 0.0125, 0.025;
];
