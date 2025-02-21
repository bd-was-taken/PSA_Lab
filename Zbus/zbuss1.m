clc;
clear;
disp('Zbus matrix by bus building algorithm ')
n=input('No of buses:');%without including reference bus
l=input('No of lines:');%all the elements to be added
line=xlsread("linedata.xlsx");% excel sheet and .m file should be saved in the location
from=line(:,1);
to=line(:,2);
z=line(:,3)+(line(:,4)*i);%the impedence added the buses
Zbus=zeros(n,n);
for i=1:n
    status(i)=0;%status=0 indicate new bus and status=1 indicate old bus
end
for j=1:l
    %type 1 modification:between new and reference bus
    if ((from(j,1)==0 && to(j,1)~=0)||(from(j,1)~=0 && to(j,1)==0))
        if j==1
            if status(to(j))==0 
                Zbus=z(j,1);
                status(to(j,1))=1;%making new bus to old
                disp(Zbus)
                continue
            end
        else
        if status(from(j,1))==0
            new=from(j);
            for k=1:from(j)-1
                Zbus(k,new)=0;
                Zbus(new,k)=0;
            end
                Zbus(new,new)=z(j,1);
                status(from(j,1))=1;
                disp(Zbus)
                continue
        end
        end
            
    end
    %type 2 modification:between new and old bus
    if (from(j,1)~=0 && to(j,1)~=0)
        if(status(from(j,1))==1 && status(to(j,1))==0)  
                  old=from(j);
                  new=to(j);
                  for k=1:new-1
                  Zbus(k,new)=Zbus(k,old);
                  Zbus(new,k)=Zbus(old,k);
              end
              Zbus(new,new)=Zbus(old,old)+z(j,1);
              status(to(j,1))=1;
              disp(Zbus)
              continue;
        end
    end
    %type 3 modification:between old and reference bus
    if (from(j,1)~=0 && to(j,1)==0)
        if(status(from(j,1))==1)
            old=from(j);
         m1=Zbus(old,old)+z(j,1);
         ztemp=(1/m1)*Zbus(:,old)*Zbus(old,:);
         Zbus=Zbus-ztemp;
         disp(Zbus)
         continue;
        end
    end
    %type 4 modification:between old and old buses
    if (from(j,1)~=0 && to(j,1)~=0)
        if(status(from(j,1))==1 && status(to(j,1))==1)
           a=from(j);
           b=to(j);
          m2=z(j,1)+Zbus(a,a)+Zbus(b,b)-(2*Zbus(a,b));
          ztemp=(1/m2)*((Zbus(:,a)-(Zbus(:,b)))*((Zbus(a,:))-(Zbus(b,:))));
          Zbus=Zbus-ztemp;
          disp(Zbus)
          continue;
        end
    end
end
fprintf('the z bus of the given matrix is\n')
disp(Zbus)

