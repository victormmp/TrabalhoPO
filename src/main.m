%% Trabalho de PO
% Bruno Pereira, Murilo Menezes, Thiago Mattar, Victor Magalhaes

%% ClearENV
clc
clear
close all force
%

%%

%% Parï¿½metros Fixos de Modelo
% Carrega influence j, que ï¿½ o modelo de quanto varia, sï¿½o as variaveis
% influence_low_j (il_j)
% influence_medium_j (im_j)
% influence_high_j (ih_j)
% do modelo. (-4 ï¿½ j = 0, -3 ï¿½ j = 1... atï¿½ 4 e j = 9)
PAR_INFLUENCE = importfileVariations("../Dados/Variations.csv", 2, 10);

% Carrega os inputs que sï¿½o os parï¿½metros de cada categoria
PAR_CATEGORIES = importfileInput("../Dados/input.csv", 2,13);

%% Parï¿½metros Definidos pelo Usuï¿½rio

% Carrega os parï¿½metros que sï¿½o relacionados ao modelo de entendimento do
% problema
% Cada mï¿½dulo adicionado ou removido, hï¿½ uma variaï¿½ï¿½o de pontos percentuais
% no draw

%PAR_crossSellInfluence_ics = input('Insira Influencia de CrossSell (em %): ');

PAR_crossSellInfluence_ics = 0.5;
PAR_boundaries = [3, 6]; %<= 3 low, <=6 medium, >6 high

% Define o tempo maximo de execucao
tempo = 500;

% Total de Tickets por Ano
PAR_ticketsPerYear_tm = 144000;

%% Pre-processamento de inputs
%   Infere numero de Categorias
M = height(PAR_CATEGORIES);
VAR = height(PAR_INFLUENCE);

category_names = PAR_CATEGORIES.category;

%   Infere se a influencia de cada categoria ï¿½ low, medium ou high
for i = 1:M
    if PAR_CATEGORIES.modulosAsIs_ai(i) <= PAR_boundaries(1)
        PAR_CATEGORIES.Low_ali(i) = 1;
        PAR_CATEGORIES.Medium_ami(i) = 0;
        PAR_CATEGORIES.High_ahi(i) = 0;
        
    elseif PAR_CATEGORIES.modulosAsIs_ai(i) <= PAR_boundaries(2)
        PAR_CATEGORIES.Low_ali(i) = 0;
        PAR_CATEGORIES.Medium_ami(i) = 1;
        PAR_CATEGORIES.High_ahi(i) = 0;
    else
        PAR_CATEGORIES.Low_ali(i) = 0;
        PAR_CATEGORIES.Medium_ami(i) = 0;
        PAR_CATEGORIES.High_ahi(i) = 1;
    end
end

%% Gera Modelo

% Tabela com as variacoes percentuais
var = table2array(PAR_INFLUENCE);

% asIs_low
ail = PAR_CATEGORIES.Low_ali;
% asIs_medium
aim = PAR_CATEGORIES.Medium_ami;
% asIs_high
aih = PAR_CATEGORIES.High_ahi;

%% Escreve Modelo

fid = fopen('model.lp','wt');

fprintf(fid, '//Implementando a funcao objetivo\n');
fprintf(fid, 'max: ');
fobj = '';

% Incluindo Lucro Direto
for i = 1:M
    %fobj = strcat(fobj, num2str(PAR_CATEGORIES.unitsSold_ui(i) ...
    %    * PAR_CATEGORIES.grossMargin_mi(i)...
    %    * PAR_CATEGORIES.unitPrice_pi(i)),'(',...
    %    '1 +');
    
    %Multiplicador de LUCRO POR VENDA DIRETA PARA O PRODUTO I
    mult = PAR_CATEGORIES.unitsSold_ui(i) ...
        * PAR_CATEGORIES.grossMargin_mi(i)...
        * PAR_CATEGORIES.unitPrice_pi(i);
    
    %DELTA LUCRO -> COMENTAR LINHA ABAIXO
    %fobj = strcat(fobj,num2str(mult),' + ');
    
    %LINHA DE VARIAÇÃO PERCENTUAL EM FUNÇÃO DA ALTERAÇÃO NA PRATELEIRA
    for j = 1:VAR
        num = (ail(i).*PAR_INFLUENCE.low_il_j(j) + ...
            aim(i).*PAR_INFLUENCE.medium_im_j(j) + ...
            aih(i).*PAR_INFLUENCE.high_ih_j(j)) * mult;
        fobj = strcat(fobj,num2str(num),'y[',num2str(i),'][',num2str(j),']');
        if(j ~= VAR)
            fobj = strcat(fobj,' + ');
        end
    end
    
    %fobj = strcat(fobj,')');
    if (i ~= M)
        fobj = strcat(fobj,'+');
    end
end

% Incluindo Lucro Indireto
fobj = strcat(fobj,' + ');

for i = 1:M
    
    mult = 0.01 * PAR_CATEGORIES.grossMarginCrossSell_mcsi(i)...
        * PAR_CATEGORIES.crossSellAVGTicket_gi(i)...
        * PAR_ticketsPerYear_tm;
    
    %fobj = strcat(fobj,'(',num2str(PAR_CATEGORIES.categoryDraw_di(i)),'+(');
    
    %fobj = strcat(fobj,num2str(PAR_CATEGORIES.categoryDraw_di(i) * mult),' + ');
    
    mult = mult * PAR_crossSellInfluence_ics;
    
    for j = 1:VAR
        
        num = (j-5)*.5;
        
        fobj = strcat(fobj,num2str(num*mult),'y[',num2str(i),'][',num2str(j),']');
        if (j ~= VAR)
            fobj = strcat(fobj,' + ');
        end%lse
        %    fobj = strcat(fobj,')');
        %end
    end
    
    %fobj = strcat(fobj,'',num2str(PAR_crossSellInfluence_ics),')',...
    %    '',num2str(0.01 * PAR_CATEGORIES.grossMarginCrossSell_mcsi(i)...
    %    * PAR_CATEGORIES.crossSellAVGTicket_gi(i)...
    %    * PAR_ticketsPerYear_tm));
    if (i~=M)
        fobj = strcat(fobj,' + ');
    end
end

fprintf(fid,[fobj ';']);

% Implementa Restricoes
fprintf(fid,'\n\n//Implementa Restricoes para y_ij unitarios\n');

for i = 1:M
    constraint = '';
    for j = 1:VAR
        constraint = strcat(constraint,'y[',num2str(i),'][',num2str(j),']');
        if (j ~= VAR)
            constraint = strcat(constraint,' + ');
        else
            constraint = strcat(constraint,'=1;\n');
        end
    end
    fprintf(fid, constraint);
end

fprintf(fid, '\n//Implementa Restricoes para um modulo por categoria\n');

for i = 1:M
    for j = 1:VAR
        %constraint = '';
        num =  (j-5) * .5;
        
        rij = strcat('r_',num2str(i),num2str(j),': ');
        constraint = strcat(rij,num2str(PAR_CATEGORIES.modulosAsIs_ai(i)),'+',...
            num2str(num),'y[',num2str(i),'][',num2str(j),...
            ']>=1;\n');
        %disp(constraint);
        if (((j-5) * .5)~=0)
            fprintf(fid, constraint);
        end
    end
end

fprintf(fid, '\n//Implementa restricao de draw positivo\n');

for i = 1:M
    for j = 1:VAR
        constraint = '';
        constraint = strcat(constraint,num2str(PAR_CATEGORIES.categoryDraw_di(i)*.01), ...
            ' + ');
        num = (j-5)*.5 * PAR_crossSellInfluence_ics * .01;
        constraint = strcat(constraint,num2str(num),...
            'y[',num2str(i),'][',num2str(j),']>=0;\n');
        fprintf(fid, constraint);
    end
end

fprintf(fid,'\n//Implementa restricao da variacao total no numero de modulos\n');

constraint = '';
for i = 1:M
    for j = 1:VAR
        num = (j - 5)*.5;
        
        constraint = strcat(constraint,num2str(num), ...
            'y[',num2str(i),'][',num2str(j),']');
        
        if (j ~= VAR)
            constraint = strcat(constraint,' + ');
        end
    end
    
    if (i ~= M)
        constraint = strcat(constraint,' + ');
    else
        constraint = strcat(constraint,'>=0;\n');
    end
end

fprintf(fid, constraint);

constraint = '\n';
for i = 1:M
    for j = 1:VAR
        
        num = (j-5) * .5;
        
        constraint = strcat(constraint,num2str(num), ...
            'y[',num2str(i),'][',num2str(j),']');
        
        if (j ~= VAR)
            constraint = strcat(constraint,'+');
        end
    end
    
    if (i ~= M)
        constraint = strcat(constraint,'+');
    else
        constraint = strcat(constraint,'<=0;\n');
    end
end

fprintf(fid,constraint);

fprintf(fid,'\n//Implementa as restricoes de variavel binaria\n');

for i = 1:M
    for j = 1:VAR
        fprintf(fid,['bin y[' num2str(i) '][' num2str(j) '];\n']);
    end
end

fclose(fid);

%% Executa LP-Solve

clc;
fprintf('> Arquivo modelo criado. Iniciando lpsolve\n');

command = ['lp_solve -s -timeout ' num2str(tempo) ' model.lp > out.txt'];

fprintf(['$ ' command '\n']);
[status,cmdout] = system(command);

if (~isempty(cmdout))
    fprintf(['\n\nLPSOLVE ERROR (' num2str(status) '): ' cmdout]);
end

%% Le o arquivo de saida

Mout=[];
fid = fopen('out.txt');
i=1;
while ~feof(fid)
    Mout{i} = fgets(fid);
    i=i+1;
end
n_lines = size(Mout,2);
fclose(fid);

value_fobj = extractAfter(Mout{2},"Value of objective function: ");
value_fobj = erase(value_fobj,value_fobj(size(value_fobj,2)));

fprintf('\n-------------- OTIMIZAÇÃO FINALIZADA -------------- \n');
disp(['Lucro adicional para a loja : R$',value_fobj]);

fobj = str2num(value_fobj);

line = 5;
final_deltas = [];

for i=1:M
    for j=1:VAR
        var = Mout{line};
        value = str2num(var(size(var,2)-2));
        if (value==1)
            final_deltas = [final_deltas (j-5)/2];
        end
        line = line + 1;
    end
end

% RGB para azul claro
color = [0.5843 0.8157 0.9882];

ModulosFinal = final_deltas' + PAR_CATEGORIES.modulosAsIs_ai;

%OUTPUT FIGURA 1 -------------- ALTERAÇÕES E CONFIGURAÇÃO
figure('units','normalized','outerposition',[0 0 1 1])
subplot(2,1,1); barh(final_deltas,'FaceColor',color)
for i=1:M
    text(0,i,char(category_names(i)));
end
xlabel('Variacao de modulos')
ylabel('Categoria')
title('Alteração na Configuração dos Módulos por Categoria');
ylim([0 (M+1)]); grid;


subplot(2,1,2); bar([ModulosFinal ...
    PAR_CATEGORIES.modulosAsIs_ai]);
set(gca,'XTickLabel',cellstr(category_names));
title('Disposição das Categorias HPC'); ylabel('Nº de módulos');
legend('Disposição Final','Disposição Inicial'); grid;

%OUTPUT FIGURA 2 ------------------ LUCRO ADICIONAL
LucroADC_CrossSell = (PAR_CATEGORIES.categoryDraw_di + final_deltas'*0.05)*0.01 * ...
    PAR_ticketsPerYear_tm .* PAR_CATEGORIES.crossSellAVGTicket_gi .* ...
    PAR_CATEGORIES.grossMarginCrossSell_mcsi;

%LucroADC_VendasDiretas = 
