clear;clc;
Fs=1000;%����Ƶ��
N=1000;%�������� Fs/N=t(������ʱ��)
%Ƶ�ʷֱ���=Fs/N�������עƵ��ΪƵ�ʷֱ��ʵ�������
n=0:1/Fs:(Fs/N-1/Fs);
xn=cos(2*pi*40*n)+3*cos(2*pi*100*n)+5*cos(2*pi*150*n)+rand(size(n));%����
ff=n(1:N/2)*Fs;
subplot(421),plot(n,xn),title('ʱ��ͼ');
xlabel('ʱ��');
ylabel('��ֵ');

%%fft
y=fft(xn,N);
y1=abs(y)*2/N;
plot_y=y1(1:(N/2));
%ploty2=plot_y/sqrt(2);
subplot(422),plot(ff,plot_y),title('Ƶ��ͼ��FFT��');
%hold on;stem(ff,plot_y,'r');
xlabel('Ƶ��/Hz');
ylabel('��ֵ');

%power spectrum����ӷ���
%nfft=1024;%index=0:round(nfft/2-1);%k=index*Fs/nfft; 
cxn=xcorr(xn,'coeff'); %�������е�����غ���
%xcorr(,'')��''��ȱʡor unbiased or biased or coeff
CXk=fft(cxn,N); 
Pxx=abs(CXk); 
plot_Pxx=10*log10(Pxx(1:N/2)); 
subplot(423),plot(ff,plot_Pxx),title('��ӷ�������غ�������������');
xlabel('Ƶ��/Hz');
ylabel('�������ܶ�');

%power spectrum��ֱ�ӷ�)
window=boxcar(length(xn)); %���δ� 
%nfft=1024; 
[Pxx,f]=periodogram(xn,window,N,Fs); %ֱ�ӷ� 
subplot(424),plot(ff,Pxx(1:N/2)),title('ֱ�ӷ���periodogram��������');
xlabel('Ƶ��/Hz');
ylabel('�������ܶ�');

%welch method 
window=boxcar(length(xn)); %���δ� 
noverlap=20; %�������ص� 
range='half'; %Ƶ�ʼ��Ϊ[0 Fs/2]��ֻ����һ���Ƶ�� 
[Pxx,f]=pwelch(xn,window,noverlap,N,Fs,range); 
%plot_Pxx=10*log10(Pxx); 
subplot(425),plot(f,Pxx),title('welch��������'); 

%welch method 
window=blackman(length(xn)); %���δ� 
noverlap=20; %�������ص� 
range='half'; %Ƶ�ʼ��Ϊ[0 Fs/2]��ֻ����һ���Ƶ�� 
[Pxx,f]=pwelch(xn,window,noverlap,N,Fs,range); 
%plot_Pxx=10*log10(Pxx); 
subplot(426),plot(f,Pxx),title('black��������'); 

% %Barlett method
% window=boxcar(length(n)); %���δ� 
% noverlap=0; %�������ص� 
% p=0.9; %���Ÿ��� 
% [Pxx,Pxxc]=psd(xn,N,Fs,window,noverlap,p); 
% %plot_Pxx=10*log10(Pxx);  
% subplot(426),plot(Pxxc,Pxx/N*2),title('barlett��������'); 
