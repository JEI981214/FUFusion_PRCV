function [X] = anisotropic2(A, f, alpha, t, Anis, Dir, Co)
%ANISOTROPIC2 Gaussian filter with varying extent and direction.
%   X = ANISOTROPIC2(A, f) smoothes image A with a Gaussian filter whose
%   direction and extent are locally adjusted to the image properties.
%
%   X = ANISOTROPIC2(A, f, alpha) Controls the extent of local variation
%   by alpha, with high values tending towards an isotropic filter. If
%   alpha is omitted it is set to 0.6.
%
%   X = ANISOTROPIC2(A, f, alpha, t) also sets a threshold t, where the
%   filter will not combine values with a difference greater than t.
%   Setting t to 0 (the default) disables this.
%
%   X = ANISOTROPIC2(A, f, alpha, t, Anis, Dir) uses local anisotropy in
%   Anis, and direction in Dir to control the filter, otherwise these are
%   calculated from the image A using STRUCTENSOR2.
%
%   X = ANISOTROPIC2(A, f, alpha, t, Anis, Dir, Co) uses the normalised
%   corner detector Co to additionally ontrol the filter, otherwise this
%   is calculated from the image A using STRUCTENSOR2.
%
%   If A is of integer type, the returned value is also integer.
%
%   See also STRUCTENSOR2, GRAD2, GAUSS2, XBITONIC2, MXBITONIC2

%   Author: Graham M. Treece, University of Cambridge, UK, Sept 2021.


% check for compiled mex file
if (exist('anisotropic2_mex','file')~=3)
  error('Type "mex anisotropic2_mex.cpp" to compile this function.');
end

% check for appropriate inputs
narginchk(2, 7);

% also check for appropriate outputs
nargoutchk(1, 1);

% other input checks
if ~(ndims(A) == 2) && ~(ndims(A) == 3)
  error('A must be a grey or colour image.');
end
if nargin<3
  alpha = 0.6;
end
if nargin<4
  t = 0;
end
if f < 1
  X = A;
  return;
end

if nargin<6
  
  % create anisotropy and direction
  [Anis, Dir, Co] = structensor2(double(A), f);
  do_corner = true;
  
else
  
  % check provided values have same dimensions as image
  if (size(A,1) ~= size(Anis,1)) || (size(A,2) ~= size(Anis,2))
    error('Anis must have the same first two dimensions as A.');
  end
  if (size(A,1) ~= size(Dir,1)) || (size(A,2) ~= size(Dir,2))
    error('Dir must have the same first two dimensions as A.');
  end
  if (nargin > 6)
    if (size(A,1) ~= size(Co,1)) || (size(A,2) ~= size(Co,2))
      error('Co must have the same first two dimensions as A.');
    end
    do_corner = true;
  else
    do_corner = false;
  end  
end

% Need to change orientation angles to make up for row-major ordering in C++
% but column-major ordering in MATLAB
Dir = mod(3*pi/2 - Dir, pi);

% go through all colour components, filtering image
X = zeros(size(A));
for k=1:size(A,3)
  
  if (size(Anis,3) == size(A,3))
    j = k;
  else
    j = 1;
  end
  
  if (do_corner)
    X(:,:,k) = anisotropic2_mex(double(A(:,:,k)), f, alpha, t, double(Anis(:,:,j)), double(Dir(:,:,j)), double(Co(:,:,j)));
  else
    X(:,:,k) = anisotropic2_mex(double(A(:,:,k)), f, alpha, t, double(Anis(:,:,j)), double(Dir(:,:,j)));
  end
  
end

% ensure the right data type
if strcmp(class(A), 'uint8')
  X = uint8(X);
elseif strcmp(class(A), 'int32')
  X = int32(X);
end