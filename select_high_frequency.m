% If you use this MATLAB code please reference the following paper. 
% Qian Jiang, Xin Jin, Xiaohui Cui, Shaowen Yao, Keqin Li, Wei Zhou, 
% A Lightweight Multimode Medical Image Fusion Method Using Similarity 
% Measure between Intuitionistic Fuzzy Sets Joint Laplacian Pyramid, 
% IEEE Transactions on Emerging Topics in Computational Intelligence, 
% 2022, accepted
% https://www.researchgate.net/profile/Qian-Jiang-29


function [R,ind ]= select_high_frequency(im1, im2)
im1=double(im1);
im2=double(im2);
imcat=[im1,im2];
[y1] =Similarity_Measure_IFS(abs(im1),imcat);
[y2] =Similarity_Measure_IFS(abs(im2),imcat);
%figure,imshow(y1);
%figure,imshow(y2);
ind=(y1-y2)>=0;
[m,n]=size(ind);
for i=1:m
    for j=1:n
        if y1(i,j)>y2(i,j)
          ind(i,j)=1;
        end
        if y1(i,j)<y2(i,j)
         ind(i,j)=0;
        end
       if y1(i,j)== y2(i,j)
         ind(i,j)=0.5;
       end
    end 
end

%figure,imshow(ind);
R=ind.*im1+(1-ind).*im2;




