clear;clc;
Fs=1000;%采样频率
N=1000;%采样点数 Fs/N=t(采样总时间)
%频率分辨率=Fs/N需满足关注频率为频率分辨率的整数倍
n=0:1/Fs:(Fs/N-1/Fs);
xn=cos(2*pi*40*n)+3*cos(2*pi*100*n)+5*cos(2*pi*150*n)+rand(size(n));%数据
ff=n(1:N/2)*Fs;
subplot(421),plot(n,xn),title('时域图');
xlabel('时间');
ylabel('幅值');

%%fft
y=fft(xn,N);
y1=abs(y)*2/N;
plot_y=y1(1:(N/2));
%ploty2=plot_y/sqrt(2);
subplot(422),plot(ff,plot_y),title('频谱图（FFT）');
%hold on;stem(ff,plot_y,'r');
xlabel('频率/Hz');
ylabel('幅值');

%power spectrum（间接法）
%nfft=1024;%index=0:round(nfft/2-1);%k=index*Fs/nfft; 
cxn=xcorr(xn,'coeff'); %计算序列的自相关函数
%xcorr(,'')中''内缺省or unbiased or biased or coeff
CXk=fft(cxn,N); 
Pxx=abs(CXk); 
plot_Pxx=10*log10(Pxx(1:N/2)); 
subplot(423),plot(ff,plot_Pxx),title('间接法（自相关函数法）功率谱');
xlabel('频率/Hz');
ylabel('功率谱密度');

%power spectrum（直接法)
window=boxcar(length(xn)); %矩形窗 
%nfft=1024; 
[Pxx,f]=periodogram(xn,window,N,Fs); %直接法 
subplot(424),plot(ff,Pxx(1:N/2)),title('直接法（periodogram）功率谱');
xlabel('频率/Hz');
ylabel('功率谱密度');

%welch method 
window=boxcar(length(xn)); %矩形窗 
noverlap=20; %数据无重叠 
range='half'; %频率间隔为[0 Fs/2]，只计算一半的频率 
[Pxx,f]=pwelch(xn,window,noverlap,N,Fs,range); 
%plot_Pxx=10*log10(Pxx); 
subplot(425),plot(f,Pxx),title('welch法功率谱'); 

%welch method 
window=blackman(length(xn)); %矩形窗 
noverlap=20; %数据无重叠 
range='half'; %频率间隔为[0 Fs/2]，只计算一半的频率 
[Pxx,f]=pwelch(xn,window,noverlap,N,Fs,range); 
%plot_Pxx=10*log10(Pxx); 
subplot(426),plot(f,Pxx),title('black法功率谱'); 

% %Barlett method
% window=boxcar(length(n)); %矩形窗 
% noverlap=0; %数据无重叠 
% p=0.9; %置信概率 
% [Pxx,Pxxc]=psd(xn,N,Fs,window,noverlap,p); 
% %plot_Pxx=10*log10(Pxx);  
% subplot(426),plot(Pxxc,Pxx/N*2),title('barlett法功率谱'); 
