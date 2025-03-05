# PSA_Lab
Experiments for PSA Lab

The folder names are the experiment
In order to run the MALTAB code, you need to install the full folder (e.g. to run Y Bus experiment, you need to install the Y bus folder for the excel files as they contain bus data and line data)

In Zbus folder, you have the necessary documentation for the formation of Z bus using bus building algorithm along with the program and the data file (excel file; .xlsx)

In Ybus folder, there is Y_bus.m program. It is the code for both Y bus and Gauss Seidel method (change the values if needed in the given bus_data.xlsx and line_data.xlsx)
Ybus.m file is the basic outline for the determination of the Y bus for a given network; more like an algorithm


In Gauss Seidel Mehtod Folder, there are three necessary files which is used for the power flow determination using Gauss Seidel method. For any changes in line data or bus data, update the excel (.xlsx) files and update the code in the Y_bus.m file for the necessary Y bus to be formed.


In Newton_Raphson folder, there are again three necessary files for the determination of power flow determination using Newton Raphson method. For any changes in line or bus data, update the excel (.xlsx) files and the code in the NR_method.m file for the necessary Y bus to be formed.
