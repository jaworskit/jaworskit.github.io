function [ d] = myFunPrices(p,tau,L,theta,Counties)

% Implements 1 iteration of the Fujimoto-Krause algorithm for equation (1.a): x_new := RHS(x_old)/||RHS(x_old)|| 

% auxiliary matrices for objective function
aux = (p.*L./sum((tau .^ -theta).* (ones(Counties,1) * L).* (ones(Counties,1) * (p .^ (1+ theta)) ) ,2)')';
tau_aux = tau.^(-theta);

temp = (tau_aux*aux)'.^(-1/theta);
d = temp/sqrt(sum(temp.^2));

end
