% function cplexbilpex
% ---------------------------------------------------------------------------
% File: cplexbilpex.m
% Version 12.6.1
% ---------------------------------------------------------------------------
% Licensed Materials - Property of IBM
% 5725-A06 5725-A29 5724-Y48 5724-Y49 5724-Y54 5724-Y55 5655-Y21
% Copyright IBM Corporation 2008, 2014. All Rights Reserved.
%
% US Government Users Restricted Rights - Use, duplication or
% disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
% ---------------------------------------------------------------------------
% [FileName1,PathName1,FilterIndex1] = uigetfile('.mat');


%% Initial Parameter
clear
clc
load('dist_matrix.mat');
% load('
dist = ans;

dist(dist<= prctile(dist,80)) = 0;
% dist = dist_matrix;
% dist = [1, 2, 3, 4, 5; 0, 0, 0, 0,0; 0, 0, 0, 0, 0; 0, 0, 0, 0, 0;  0, 0, 0, 0, 0;];
NUM_BARS = length(dist);

%% Enumerate Remotes
NUM_REMOTES = 4; % NUM_REMOTES >= 2

%% Burlando
% NUM_BARS = 80;

%% Enumerate the combinations
PAIRS_ij = nchoosek([1:NUM_BARS],2);
NUM_PAIRS = size(PAIRS_ij, 1);

% Determine number of variables
NUM_VARS = NUM_BARS + NUM_PAIRS;

%% Create a of x's, the boolean vars
ax = zeros(1,NUM_BARS);

%% Create a of yij, the non obligatory boolean variables. It is Dij.
ayij = zeros(1,NUM_PAIRS);
for ij = 1:NUM_PAIRS
    
    i = PAIRS_ij(ij,1);
    
    j = PAIRS_ij(ij,2);
    
    ayij(ij) = dist(i,j);
end

f = [ax ayij];
f = -f;

%% FOR EVERY PAIR YIJ, CREATE 2 NEW INEQUALITIES:
% YIJ - XI <= 0 E YIJ - XJ <= 0;
NUM_INEQUALITIES = 2*NUM_PAIRS;
Aineq = zeros(NUM_INEQUALITIES, NUM_VARS);
bineq = zeros(NUM_INEQUALITIES,1);
for k = 1:NUM_INEQUALITIES
    ij = NUM_BARS + k;
    if k<= NUM_PAIRS    % CREATE: yij - xi <= 0
        i = PAIRS_ij(k,1);
        Aineq(k, ij) = +1;
        Aineq(k, i) = -1;
        bineq(k) = 0;
    else                % CREATE: yij - xj <= 0
        j = PAIRS_ij(k-NUM_PAIRS, 2);
        Aineq(k, ij-NUM_PAIRS) = 1;
        Aineq(k, j) = -1;
        bineq(k) = 0;
    end
end


%% CREATE ONE EQUALITY:
Aeq = zeros(1,NUM_VARS);
beq =  NUM_REMOTES;  
for i = 1:NUM_BARS
    Aeq(i) = 1;
end

%% DEFINE LOWER AND UPPER LIMITS
lb = zeros(NUM_VARS,1);
ub = zeros(NUM_VARS,1);
ctype = [];
for i = 1:NUM_VARS
    lb(i) = 0;
    if i<=NUM_BARS
        ub(i) = 1;
        ctype = [ctype 'B'];
    else
        ub(i) = inf;
        ctype = [ctype 'C'];
    end
end


%% RUN CPLEX
options = cplexoptimset('cplex');
options.Display = 'on';

[x, fval, exitflag, output] = cplexmilp(f, Aineq, bineq, Aeq, beq,...
  [ ], [ ], [ ], lb, ub, ctype, [ ], options);
% [x, fval, exitflag, output] = cplexbilp(f, Aineq, bineq, Aeq, beq, ...
%   [ ], options);

%% PRINT CPLEX
fprintf ('\nSolution status = %s \n', output.cplexstatusstring);
fprintf ('Solution value = %f \n', fval);
disp ('Values =');
% disp (x');

r_found = find(x);
rem_ij = r_found(r_found>NUM_BARS) - NUM_BARS;

found_pairs = PAIRS_ij(rem_ij, :);
found_ijs = unique(found_pairs);
str_result = 'Remotas em:';
for k = 1:length(found_ijs)
    str_result = [str_result ' ' num2str(found_ijs(k))];
    if k ~=length(found_ijs)
        str_result = [str_result ';'];
    end
end
str_result























