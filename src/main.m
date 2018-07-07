%% Trabalho de PO
% Bruno Pereira, Murilo Menezes, Thiago Mattar, Victor Magalhaes

%% ClearENV
clc
clear
close all force
%

%%

%% Par�metros Fixos de Modelo
% Carrega influence j, que � o modelo de quanto varia, s�o as variaveis
    % influence_low_j (il_j)
    % influence_medium_j (im_j)
    % influence_high_j (ih_j)
% do modelo. (-4 � j = 0, -3 � j = 1... at� 4 e j = 9)
PAR_INFLUENCE = importfileVariations("../Dados/Variations.csv", 2, 10);

% Carrega os inputs que s�o os par�metros de cada categoria
PAR_CATEGORIES = importfileInput("../Dados/Input.csv", 2, 10);

%% Par�metros Definidos pelo Usu�rio

% Carrega os par�metros que s�o relacionados ao modelo de entendimento do
% problema
% Cada m�dulo adicionado ou removido, h� uma varia��o de pontos percentuais
% no draw

%PAR_crossSellInfluence_ics = input('Insira Influencia de CrossSell (em %): ');

PAR_crossSellInfluence_ics = 0.5;
PAR_boundaries = [3, 6]; %<= 3 low, <=6 medium, >6 high

%% Pre-processamento de inputs
%   Infere n�mero de Categorias
M = height(PAR_CATEGORIES);

%   Infere se a influencia de cada categoria � low, medium ou high
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

fprintf(fid, 'max T;\n\n');


fclose(fid);











