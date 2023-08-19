function [siml]=dice_k2(k1,k2)
% Dice similarity coefficient for k-means parcellations (k=2)

siml=sum((k1==1).*(k2==1)+(k1==2).*(k2==2))/sum(k1>0);

end
