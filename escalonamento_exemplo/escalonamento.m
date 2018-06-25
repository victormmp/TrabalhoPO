% Script did?tico para o problema de escalonamento
% criado por Vinicius Mariano Gon?alves - Pesquisa Operacional - Universidade Federal
% de Minas Gerais

clc;
clear all;

%N?mero de m?quinas
N=15;
%N?mero de trabalhos
M=60;
%Tempo maximo (em segundos) para resolver o problema
tempo=60;

%Cria as matrizes
%%N?O MUDE AQUI%%%
P = zeros(M,M);
Q = zeros(M,2);
%%N?O MUDE AQUI%%%

%Matriz P de preced?ncia: P(j1,j2) = 1 se o trabalho j1  precisa acontecer
%depois do trabalho j2, e P(j1,j2)=0 se n?o houver essa restri??o

%Sorteia uma matriz ac?clica;
for i = 1: M
for j = i+1:M
  if rand()>0.95
   P(i,j) = 1;
  end
end
end

%Aloca cada trabalho para uma maquina, a sintaxe e a seguinte: Q(j,1) 
%indica em qual maquina o trabalho j devera ser feito, enquanto Q(j,2)
%e o tempo que ele gasta para ser feito
for j = 1: M
 Q(j,1) = round((N-1)*rand())+1;
 Q(j,2) = round(15*rand())+3;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%NAO MUDE DE AQUI EM DIANTE%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Pr?-processa a matriz P
P = (eye(M)-P)^(-1)-eye(M);
P = min(round(P),1);


%Cria o arquivo .lp no lp solve
fid = fopen('model.lp','wt');

fprintf(fid, 'min: T; \n\n\n');

fprintf(fid, '//Implementa a funcao objetivo \n');
for j=1:M
 fprintf(fid, ['T>=F[' num2str(j) '];\n']);      
end

fprintf(fid, '\n // Restricoes de precedencia \n');
for j1=1:M
for j2=1:M
  if P(j1,j2)==1 %H? uma restri??o de preced?ncia
  fprintf(fid, ['I[' num2str(j1) ']>=F[' num2str(j2) '];\n']);    
  end
end
end

fprintf(fid, '\n // Implementa as restricoes de tempo \n');

for j=1:M
 fprintf(fid, ['F[' num2str(j) ']-I[' num2str(j) ']>=' num2str(Q(j,2))  ';\n']);      
end

fprintf(fid, '\n // Implementa as restricoes de nao colisao \n');

%Usa as mesmas constantes Mp e Mn para todos
Mc = sum(Q(:,2));

for j1=1:M
for j2=j1+1:M
    
  if (Q(j1,1)==Q(j2,1))&(P(j1,j2)+P(j2,j1)==0) %Elas est?o alocadas na mesma m?quina e nao tem restricao de precedencia
   fprintf(fid, ['u[' num2str(j1) '][' num2str(j2) '] + u[' num2str(j2) '][' num2str(j1) '] >= 1;\n']);
   
   fprintf(fid, [num2str(Mc) 'u[' num2str(j1) '][' num2str(j2) ']>= I[' num2str(j1) ']-F[' num2str(j2) '];\n']);
   fprintf(fid, [num2str(Mc) '-' num2str(Mc) 'u[' num2str(j1) '][' num2str(j2) ']>= F[' num2str(j2) ']-I[' num2str(j1) '];\n']);
   
   fprintf(fid, [num2str(Mc) 'u[' num2str(j2) '][' num2str(j1) ']>= I[' num2str(j2) ']-F[' num2str(j1) '];\n']);
   fprintf(fid, [num2str(Mc) '-' num2str(Mc) 'u[' num2str(j2) '][' num2str(j1) ']>= F[' num2str(j1) ']-I[' num2str(j2) '];\n']);
   
   fprintf(fid,'\n');
   
  end
end
end

fprintf(fid, '\n // Implementa as restricoes de variaveis binarias\n');

for j1=1:M
for j2=j1+1:M
    
  if (j1~=j2)&(Q(j1,1)==Q(j2,1)) %Elas est?o alocadas na mesma m?quina
   fprintf(fid, ['bin u[' num2str(j1) '][' num2str(j2) '];\n']);
   fprintf(fid, ['bin u[' num2str(j2) '][' num2str(j1) '];\n']);
   
  end
end
end


fclose(fid);

%Resolve o problema e cria os vetores F e I
I=zeros(1,M);
F=zeros(1,M);

command = ['lp_solve -s -timeout ' num2str(tempo) ' model.lp > out.txt'];
[status,cmdout] = system(command);

disp('Terminou!!!');

%Processa o arquivo 'out.txt';

%Coloca todas as linhas no vetor de strings Mout
Mout=[];
fid = fopen('out.txt');
i=1;
while ~feof(fid)
    Mout{i} = fgets(fid);
    i=i+1;
end
fclose(fid);

%Encontra todas as vari?veis do tipo I[k]
for j = 1: M
 tam = floor(log(j)/log(10))+1;
 i=1;
 tline =Mout{i};
 while (length(tline)<3+tam)||(~prod(tline(1:3+tam) == [ 'I[' num2str(j) ']' ]))
  tline = Mout{i+1};
  i=i+1;
 end
 tline(1:3+tam)=[];
 I(j)=str2num(tline);
 Mout(i)=[];
end

%Encontra todas as vari?veis do tipo F[k]
for j = 1: M
 tam = floor(log(j)/log(10))+1;
 i=1;
 tline =Mout{i};
 while (length(tline)<3+tam)||(~prod(tline(1:3+tam) == [ 'F[' num2str(j) ']' ]))
  tline = Mout{i+1};
  i=i+1;
 end
 tline(1:3+tam)=[];
 F(j)=str2num(tline);
 Mout(i)=[];
end

disp(['Makespan encontrado: ' num2str(max(F))]);


%Distribui cores para cada m?quina
for i = 1: N
Cor(i,:) = 0.3+0.5*rand(1,3);
end

%Desenha a solu??o na tela

figure();
hold on;
for i = 1: N
 for j = 1: M
  if Q(j,1)==i
    rectangle('Position',[I(j),i-1,F(j)-I(j),1],'FaceColor',Cor(i,:),'EdgeColor','k',...
    'LineWidth',2);
    text(0.7*I(j)+0.3*F(j),i-0.5,num2str(j));
  end
 end
end



hold off;


