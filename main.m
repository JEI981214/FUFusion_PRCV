clc
close all 
clear all

AA=imread('vi.tif');
BB=imread('ir.tif');
figure,imshow(AA);
figure,imshow(BB);


if size(BB,3)>1
    BB=rgb2gray(BB);        
end

A=im2double(AA);
B=im2double(BB);
%% Fusion method
Q=6;
AL=BLF_LS5(A,Q);
BL=BLF_LS5(B,Q);
AH=A-AL;
BH=B-BL;
%------------------------------------- High frequence------------------------------------------
%% Significant edge
I1=im2double(AH); 
% Sobel
[gradientX, gradientY] = gradient(I1);
gradientX(gradientX > 1) = 1;
gradientX(gradientX < -1) = -1;
gradientY(gradientY > 1) = 1;
gradientY(gradientY < -1) = -1;
Ix=gradientX;
Iy=gradientY;
%fuzzy inferrence system
edgeFIS=newfis('edgeDetection');
%input
edgeFIS = addvar(edgeFIS,'input','Ix',[-1 1]);
edgeFIS = addvar(edgeFIS,'input','Iy',[-1 1]);

%sx and sy as the corresponding sigma standard deviation in the Gaussian affiliation function, respectively
sx=0.1;
sy=0.1;
edgeFIS = addmf(edgeFIS,'input',1,'zero','gaussmf',[sx 0]);
edgeFIS = addmf(edgeFIS,'input',2,'zero','gaussmf',[sy 0]);
%output
edgeFIS = addvar(edgeFIS,'output','Iout',[0 1]);
%trigonometric subordinate function
wa = 0.1;
wb = 1;
wc = 1;
ba = 0;
bb = 0;
bc = 0.7;
%Parameter description: fis = addmf(fis,varType,varIndex,mfName,mfType,mfParams)
edgeFIS = addmf(edgeFIS,'output',1,'white','trimf',[wa wb wc]);
edgeFIS = addmf(edgeFIS,'output',1,'black','trimf',[ba bb bc]);

r1 = 'If Ix is zero and Iy is zero then Iout is black';
r2 = 'If Ix is not zero or Iy is not zero then Iout is white';
r = char(r1,r2);
edgeFIS = parsrule(edgeFIS,r);
showrule(edgeFIS)

%Each row of pixels is fed into the fuzzy system for evaluation and the output is obtained
Ieval1 = zeros(size(I1));
for ii = 1:size(I1,1)
    Ieval1(ii,:) = evalfis([(Ix(ii,:));(Iy(ii,:));]',edgeFIS);
end

%figure,imshow(Ieval1);

% fuzzy inference system2
I2=im2double(BH);
[gradientX, gradientY] = gradient(I2);
gradientX(gradientX > 1) = 1;
gradientX(gradientX < -1) = -1;
gradientY(gradientY > 1) = 1;
gradientY(gradientY < -1) = -1;
Ix=gradientX;
Iy=gradientY;
%Defining a fuzzy inference system for image edge detection
edgeFIS=newfis('edgeDetection');
%定义模糊推理系统的输入
edgeFIS = addvar(edgeFIS,'input','Ix',[-1 1]);
edgeFIS = addvar(edgeFIS,'input','Iy',[-1 1]);

%sx and sy as the corresponding sigma standard deviation in the Gaussian affiliation function, respectively
sx=0.1;
sy=0.1;
edgeFIS = addmf(edgeFIS,'input',1,'zero','gaussmf',[sx 0]);
edgeFIS = addmf(edgeFIS,'input',2,'zero','gaussmf',[sy 0]);
%Define the output of the fuzzy inference system
edgeFIS = addvar(edgeFIS,'output','Iout',[0 1]);

%trigonometric subordinate function
wa = 0.1;
wb = 1;
wc = 1;
ba = 0;
bb = 0;
bc = 0.7;
%Parameter description: fis = addmf(fis,varType,varIndex,mfName,mfType,mfParams)
edgeFIS = addmf(edgeFIS,'output',1,'white','trimf',[wa wb wc]);
edgeFIS = addmf(edgeFIS,'output',1,'black','trimf',[ba bb bc]);

r1 = 'If Ix is zero and Iy is zero then Iout is black';
r2 = 'If Ix is not zero or Iy is not zero then Iout is white';
r = char(r1,r2);
edgeFIS = parsrule(edgeFIS,r);
showrule(edgeFIS)
%output
Ieval2 = zeros(size(I2));
for ii = 1:size(I2,1)
    Ieval2(ii,:) = evalfis([(Ix(ii,:));(Iy(ii,:));]',edgeFIS);
end
%%
thr1 = graythresh(Ieval1);
Ieval11 = imbinarize(Ieval1,thr1);
thr2 = graythresh(Ieval2);
Ieval22 = imbinarize(Ieval2,thr2);
Ieval11=im2double(Ieval11);
Ieval22=im2double(Ieval22);

r2=4;
eps = 0.02^2;
S=4
Ieval111 =guidedfilter(AH, Ieval11, r2, eps);
Ieval222 =guidedfilter(BH, Ieval22, r2, eps);
FH1=Ieval111.*AH+Ieval222.*BH;

T1=Ieval111.*AH;
T2=Ieval222.*BH;
%% insignificant edge
AH2=AH-Ieval111.*AH;
BH2=BH-Ieval222.*BH;
%% --------------------------------------------------------------------
FH=select_high_frequency(AH2, BH2);%Similarity_Measure_Between_Intuitionistic_Fuzzy_Sets
%figure,imshow(FH,[]);
%% %-------------------------------------low frequency-------------------------------------
map2=(AL>BL);
figure,imshow(map2);
FL=AL.*map2+BL.*(1-map2);
%% %------------------------------------fused image----------------------------------------
F=FL+FH1+FH;
figure,imshow(F);
