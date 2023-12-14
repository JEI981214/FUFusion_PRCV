% read in image
A = imread('varying_noise.png','PNG');

% Run filters and show results
for i = 1:4
  
  switch (i)
    case 1
      title = 'Original image';
      B = A;
      
    case 2
      title = 'Bitonic, f=6';
      fprintf(1,'Calculating bitonic ... ');
      tic;
      B = bitonic2(A, 6);
      t = toc;
      fprintf(1,'in %.3f secs.\n', t);
      
    case 3
      title = 'Structurally varying bitonic, f=10';
      fprintf(1,'Calculating structurally varying bitonic ... ');
      tic;
      B = svbitonic2(A, 10);
      t = toc;
      fprintf(1,'in %.3f secs.\n', t);

    case 4
      title = 'Multi-resolution varying bitonic, f=9';
      fprintf(1,'Calculating multi-resolution varying bitonic ... ');
      tic;
      B = mvbitonic2(A, 9);
      t = toc;
      fprintf(1,'in %.3f secs.\n', t);

  end
  
  figure(i);
  imagesc(B);
  colormap(gray);
  pos = get(i, 'Position');
  pos(3:4) = [167 168] * 2; % scale image by 2
  set(i,'Position',pos);
  text(8,160,title,'Color',[1 1 0]);
  axis off;
  set(gca,'Position',[0 0 1 1]);
  set(gca,'Box','off');
  caxis([0 255]);

end