% If you use this MATLAB code please reference the following paper. 
% Qian Jiang, Xin Jin, Xiaohui Cui, Shaowen Yao, Keqin Li, Wei Zhou, 
% A Lightweight Multimode Medical Image Fusion Method Using Similarity 
% Measure between Intuitionistic Fuzzy Sets Joint Laplacian Pyramid, 
% IEEE Transactions on Emerging Topics in Computational Intelligence, 
% 2022, accepted
% https://www.researchgate.net/profile/Qian-Jiang-29


function [d]=Similarity_Measure_IFS(im11,imcat)
c=mean2(imcat);
a=min(min(imcat));
a1=max(max(imcat));
mf=trimf(im11, [(a) c (a1-0.4*a1)]);
alpa=2;
ul=power(mf,alpa); 
uu=power(mf,1/alpa);
mu=ul;     
mv=1-uu;       
mt=1-mu-mv;  
[m,n]=size(mf);
upoint=ones(m,n);
vpoint=zeros(m,n);
tpoint=vpoint;
d0=(abs((mu-upoint).*sqrt(upoint.^2+mu.^2)./(upoint+mu))...
            +abs(vpoint-mv.*sqrt((1-vpoint).^2+(1-mv.^2))./(2-vpoint+mv)))./2;   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
link_arrange=9;
center_x=round(link_arrange/2);
center_y=round(link_arrange/2);
W=zeros(link_arrange,link_arrange);
for i=1:link_arrange
    for j=1:link_arrange
        if (i==center_x)&&(j==center_y)
            W(i,j)=0;
        else
            W(i,j)=1./sqrt((i-center_x).^2+(j-center_y).^2);
        end
    end
end
W(center_x,center_y)=1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%
d=conv2(d0,W,'same'); 
dv=d;
dt=d;
