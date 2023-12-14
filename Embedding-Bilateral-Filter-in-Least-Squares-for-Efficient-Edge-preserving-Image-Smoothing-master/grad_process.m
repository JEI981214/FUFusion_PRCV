function image=grad_process(S,v,h,beta)
    betamax=1e5;%
    fx=[1,-1];
    fy=[1;-1];
    [N,M,D]=size(S);
    sizeI2D=[N,M];
    otfFx=psf2otf(fx,sizeI2D);
    otfFy=psf2otf(fy,sizeI2D);
    Normin1=fft2(S);
    Denormin2=abs(otfFx).^2+abs(otfFy).^2;
    Denormin2=repmat(Denormin2,[1,1,D]);
    Denormin=1+beta*Denormin2;

    Normin2=[h(:,end,:)-h(:,1,:),-diff(h,1,2)];
    Normin2=Normin2+[v(end,:,:)-v(1,:,:);-diff(v,1,1)];
    FS=(Normin1+beta*fft2(Normin2))./Denormin;
    image=real(ifft2(FS));
end

