function [X] = mxbitonic2(A, va)
%MXBITONIC2 multi-resolution flexible threshold-based bitonic filter.
%   X = MXBITONIC2(A) filters A with a set of locally-adaptive masks
%   using an automatically calculated threshold and filter extent.
%
%   The input A can be a grey 2D image, or a three colour (eg. RGB) image,
%   or a 4 channel planar CFA image, such as would be generated by using
%   rawread followed by raw2planar.
%
%   The class of A can be either double, int32 or uint8. Processing is
%   considerably faster when using int32 or uint8, which is the default for
%   image data. The presumed data range is 0 to 1 for double, 0 to 255 for
%   uint8 and is not set for int32.
%
%   X = MXBITONIC2(A, noise, ...) should be used to set the noise type to
%   'additive' (if the noise has been added after the image was created),
%   or 'sensor' (if the image only contains real sensor noise). This is an
%   optional argument, but must always be the second argument if it exists,
%   and potentially makes a big difference to the result. The default is
%   'additive'.
%
%   X = MXBITONIC2(A, t) uses a threshold t, representing the range of
%   noise in the data. This should normally be set to four times the
%   standard deviation of the noise in A. If t < 0 then it will be set
%   automatically. It is better to set this if it is known.
%
%   X = MXBITONIC2(A, t, f) also uses a filter and mask size of l x l,
%   where l = 2 * f + 1. f is typically in the range 4 to 9, depending on 
%   the amount of noise in the image. If f < 0 then it will be set
%   automatically.
%
%   X = MXBITONIC2(A, t, f, centile) uses centile as the minimum centile
%   for the morphological operations. The default (which is nearly always
%   the best choice) is 8.
%
%   X = MXBITONIC2(A, t, f, centile, levels) uses levels as the maximum
%   number of multiresolution levels. The default (which is nearly always
%   the best choice) is 5.
%
%   Example:
%     A = imread('demo_data.png');
%     image(A)
%     B = mxbitonic2(A);
%     image(B);
%
%   See also XRANKOPEN2, ANISOTROPIC2, XBITONIC2

%   Author: Graham M. Treece, University of Cambridge, UK, Sept 2021.


% check for appropriate inputs
narginchk(1, 6);
v = 1;
noise = 'additive';
if (nargin>v)
  if ischar(va{v})
    noise = va{v};
    if (~strcmp(noise, 'sensor') && ~strcmp(noise, 'additive'))
      error("Noise must be either 'sensor' or 'additive'.");
    end
    if (strcmp(noise, 'sensor') && strcmp(class(A), 'int32') && (size(A,3) ~= 4))
      warning("Range of int32 data is presumed to be 0 to 3*255.");
      % since this doesn't have a presumed maximum level
    end;
    v = v + 1;
  end
end
if (nargin>v)
  t = va{v};
  v = v + 1;
else
  % need to automate noise threshold from A
  t = -1;
end
if (nargin>v)
  f = va{v};
  v = v + 1;
else
  % need to automate filter length from t
  f = -1;
end
if (nargin>v)
  centile = va{v};
  v = v + 1;
else
  % always defaults to 8
  centile = 8;
end
if (nargin>v)
  levels = va{v};
  if (levels < 1)
    levels = 1;
  end
else
  % always defaults to 5
  levels = 5;
end

% also check for appropriate outputs
nargoutchk(1, 1);

% check for compiled mex file
if (exist('xrankopen2','file')~=3)
  error('Type "mex xrankopen2.cpp" to compile this function.');
end
if (exist('anisotropic2_mex','file')~=3)
  error('Type "mex anisotropic2_mex.cpp" to compile this function.');
end

% possibly automate thresholds and filter length
if (t<0) || (f<0)
  [m n c] = size(A);
  if strcmp(class(A), 'uint8')
    minval = 0;
    maxval = 255;
  elseif strcmp(class(A), 'double')
    minval = 0.0;
    maxval = 1.0;
  else
    [minval, maxval] = bounds(A(:));
  end
  if (t<0)
    
    % Get std of noise from image and convert to threshold
    if strcmp(noise, 'sensor')
      if (c==4)
        t = estimate_image_noise(A);
      else
        t = estimate_image_noise(A, 2);
      end
      t = 5.5 * t;
    else
      t = estimate_image_noise(A);
      t = 4.0 * t;
    end
    
    % reduce this for low noise scenarios
    t = t * (1.0 - 0.75 * exp( - (t*12)/double(maxval-minval) ));
    
  end
  if (f<0)
    if strcmp(noise, 'sensor')
      if (c==4)
        f = round(2.5 + log2(((t*4/5.5)/double(maxval-minval))/0.071));
      else
        f = round(2.5 + log2(((t*4/5.5)/double(maxval-minval))/0.05));
      end
    else
      f = round(2.5 + log2((t/double(maxval-minval))/0.02));
    end
    if (f<3)
      f = 3;
    elseif (f>10)
      f = 10;
    end
  end
  
  % Ensure user can see these estimates
  fprintf(1, "Using threshold %.3f and filter length %i.\n", t, f);
end

% initial input at first level is A
% need to use int32 rather than uint
% and multiply by 3 to get some additional precision
if strcmp(class(A), 'uint8')
  scale = 3.0;
  B{1} = int32(A)*scale;
  t = t*scale;
else
  scale = 1.0;
  B{1} = A;
end

% Work out thresholds for all levels, and limit max levels according
% to threshold and also filter size
levels = min([levels ceil(log2(min([size(A,1) size(A,2)]) / (2*f + 1)))]);
thresh = zeros(levels, 1);
thresh(1) = t;
thresh(2) = thresh(1) / (f * 2.4);
for th=3:levels
  thresh(th) = thresh(th-1) / 2.0;
end
if ~strcmp(class(A), 'double')
  thresh = int32(round(thresh));
  thresh = thresh(thresh>=scale);
  levels = min([levels length(thresh)]);
end

% Go down through levels, processing and restricting
for l=1:levels
  
  % Apply bitonic at this level
  B2{l} = xbitonic2(B{l}, noise, thresh(l), f, centile, l-1);
  
  % possibly restrict and correct ready for deeper levels
  if (l < levels)
    B{l+1} = restrict2(B2{l});
    B2{l} = B2{l} - prolongate2(B{l+1}, size(B2{l}));
  end
  
end

% Go up through levels, prolongating and adding result
for l=(levels-1):-1:1
  
  % add in prolongated lower level result
  B2{l} = B2{l} + prolongate2(B2{l+1}, size(B2{l}));

  % additional bitonic with lower threshold
  B2{l} = xbitonic2(B2{l}, noise, thresh(l+1), f, centile, -l);

end

% result is processed output at top level
if strcmp(class(A), 'uint8')
  X = uint8(B2{1}/scale);
else
  X = B2{1};
end
  