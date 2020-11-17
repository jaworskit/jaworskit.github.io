clear all; clc;

cd '/Users/taylorjaworski/Dropbox/Papers/EH/RegionalDevelopment/transportation/LongRunMarketAccess/matlab'

years = [1920 1930 1940 1950 1960 1970 1980 1990 2000 2010];
costs = [1];

for t = years
for c = costs 
    
    yearFact = num2str(t);
	costFact = num2str(c);
    disp('*************************');
    disp(['* year = ' yearFact ', cost = ' costFact ' *']);
    disp('*************************');
    
    % load market size (=LABOR) data
    Y = csvread(['input/L' yearFact '.csv']);
    Y = Y';
    
    % load fips codes
    fips = csvread(['input/FIPS.csv'])';
    fips = fips(1,1:3080);

    % load trade cost data, by year and cost parameters
	tauFact = csvread(['input/Tau' yearFact 'cost' costFact '.csv']);
    tauFact( :, all( ~any( tauFact ), 1 ) ) = [];
    tauFact( ~any( tauFact ,2), : ) = [];
    
    % set number of counties
    Counties = length(Y);
  
    % set theta for this iteration
    th = 8;

    % solve for market access for this iteration of theta
    maFact = SolvePrices(Y,tauFact,th,Counties);
    %maFact = SolveMA(Y,tauFact,th,Counties);
    
    % export final data
    %dlmwrite(['output/MA' yearFact '_cost' costFact '.csv'],[fips', maFact'],'delimiter',',','precision',17);
  
end
end
