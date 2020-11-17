function [p] = SolvePrices(L, tau, theta, Counties)

        x0 = ones(1,Counties);
        %x0 = rand(1, Counties);
        Tol = 10^-4;
        new = myFunPrices(x0,tau,L,theta,Counties);
        x = x0;
        
        
        while (sqrt(sum((new - x).^2)) > Tol)
            %sum((new - x).^2)
            x = new;
            new = myFunPrices(new,tau,L,theta,Counties);
            sum((new - x).^2)
        end
        
        p = new;
           
    
    
end
