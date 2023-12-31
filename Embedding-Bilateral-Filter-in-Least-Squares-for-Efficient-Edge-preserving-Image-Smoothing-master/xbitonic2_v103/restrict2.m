function [X] = restrict2(A)
%RESTRICT2 restriction operation for use in multi-level methods.
%   X = RESTRICT2(A) returns a half-size array X which is a restriction of
%   A using an edge-preserving Catmull-Rom operator.
%
%   See also PROLONGATE2, MXBITONIC2

%   Author: Graham M. Treece, University of Cambridge, UK, Sept 2021.


% check for appropriate inputs
narginchk(1, 1);

% also check for appropriate outputs
nargoutchk(1, 1);

% other input checks
if ~(ndims(A) == 2) && ~(ndims(A) == 3)
  error('A must be a grey or colour image.');
end

% set up a catmull rom restriction operator and extension vectors
h = [-1 0 9 16 9 0 -1]/32;
%h = [1 8 23 32 23 8 1]/96;
hh = length(h);
m = [ones(1,3) 1:size(A,1) size(A,1)*ones(1,3)];
n = [ones(1,3) 1:size(A,2) size(A,2)*ones(1,3)];
mm = length(m);
modd = mod(mm,2);
nn = length(n);
nodd = mod(nn,2);
nnn = ceil( (nn - 1 + hh)/2 );

% filter and remove edge samples
if (rem(size(A,1),2)==1)
  off1 = 3;
else
  off1 = 2;
end
if (rem(size(A,2),2)==1)
  off2 = 3;
else
  off2 = 2;
end
for k=1:size(A,3)
  
  % This version does not need the signal processing toolbox
  if nodd
    b = conv2(h(1:2:hh), double(A(m,n(1:2:nn),k))) + [zeros(mm,1) conv2(h(2:2:hh), double(A(m,n(2:2:nn),k))) zeros(mm,1)];
  else
    b = conv2(h(1:2:hh), double(A(m,n(1:2:nn),k))) + [zeros(mm,1) conv2(h(2:2:hh), double(A(m,n(2:2:nn),k)))];
  end
  if modd
    c = conv2(h(1:2:hh)', b(1:2:mm,:)) + [zeros(1,nnn); conv2(h(2:2:hh)', b(2:2:mm,:)); zeros(1,nnn)];
  else
    c = conv2(h(1:2:hh)', b(1:2:mm,:)) + [zeros(1,nnn); conv2(h(2:2:hh)', b(2:2:mm,:))];
  end
  X(:,:,k) = c(4:(end-off1),4:(end-off2));
  
  % this version does
  %X(:,:,k) = upfirdn(upfirdn(double(A(m,n,k)), h, 1, 2)', h, 1, 2)';
  
end
%X = X(4:(end-off1),4:(end-off2),:);

% ensure the right data type
if strcmp(class(A), 'uint8')
  X = uint8(X);
elseif strcmp(class(A), 'int32')
  X = int32(X);
end