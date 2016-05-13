function test_spectrum(TotalBurstNum,iOsr,FftLen,)

%%clc; close all;clear


pxx = periodogram(x);
% set params
TotalBurstNum = 100;
iOsr = 96;
FftStartPoint = 1;
FftLen = 148 * iOsr;

for t = 1:4
if t==1
    % read sample from c
EdgeModFxp = textread('iload.txt') + (1i)*textread('qload.txt');
elseif t==2
    % read sample from c
EdgeModFxp = textread('iload_rect8x.txt') + (1i)*textread('qload_rect8x.txt');
elseif t==3
EdgeModFxp = textread('iload_black8x.txt') + (1i)*textread('qload_black8x.txt');  
elseif t==4
    % read sample from c
EdgeModFxp = textread('iload_blackh8x.txt') + (1i)*textread('qload_blackh8x.txt');
end
SpectrumAvg = zeros(FftLen,1);

Win = blackman(FftLen).';
% Win = ones(1,FftLen);
for iNumOfBurst = 1 : TotalBurstNum

    vBurstModFxp = EdgeModFxp((iNumOfBurst-1)*FftLen+1:(iNumOfBurst*FftLen)).';
    
    % spectrum analysis
    vOutForAnalysis = vBurstModFxp(FftStartPoint:FftStartPoint+FftLen-1) .* Win;
    Spectrum(:,iNumOfBurst) = (abs(fft(vOutForAnalysis,FftLen)/(FftLen/2))).^2;
    SpectrumAvg = SpectrumAvg + Spectrum(:,iNumOfBurst);
    
end

SpectrumAvg = [SpectrumAvg(end/2+1:end);SpectrumAvg(1:end/2)];
for k = 1 : FftLen
        SpectrumAvg(k) = mean(SpectrumAvg(max(1,k-8):min(k+8,FftLen)));
end
SpectrumAvgHalf(1,:) = (SpectrumAvg(end/2+1:end)) ;

figure(1);hold on;
if t==1
plot(linspace(0,0.5,FftLen/2)* 13e6/48*iOsr, 10 * log10((SpectrumAvgHalf(1,:))/TotalBurstNum)-max(10 * log10((SpectrumAvgHalf(1,:))/TotalBurstNum)),'-b','linewidth',2);hold on
elseif t==2
    plot(linspace(0,0.5,FftLen/2)* 13e6/48*iOsr, 10 * log10((SpectrumAvgHalf(1,:))/TotalBurstNum)-max(10 * log10((SpectrumAvgHalf(1,:))/TotalBurstNum)),'-c','linewidth',2);hold on
elseif t==3
    plot(linspace(0,0.5,FftLen/2)* 13e6/48*iOsr, 10 * log10((SpectrumAvgHalf(1,:))/TotalBurstNum)-max(10 * log10((SpectrumAvgHalf(1,:))/TotalBurstNum)),'-m','linewidth',2);hold on
elseif t==4
    plot(linspace(0,0.5,FftLen/2)* 13e6/48*iOsr, 10 * log10((SpectrumAvgHalf(1,:))/TotalBurstNum)-max(10 * log10((SpectrumAvgHalf(1,:))/TotalBurstNum)),'-k','linewidth',2);hold on
end
end
%% plot mask
FreqRange =0:100:6000e3 ;
for k=1: length(FreqRange)
    if FreqRange(k) <= 100e3
        mask(k) = 0.5;
    elseif FreqRange(k) <= 200e3
        mask(k) = -30.5/100e3 * FreqRange(k) +31;
    elseif FreqRange(k) <= 250e3
        mask(k) = -3/50e3 * FreqRange(k) -18;
    elseif FreqRange(k) <= 400e3
        mask(k) = -27/150e3 * FreqRange(k) +12;
    elseif FreqRange(k) <= 600e3
        mask(k) = -6/200e3 * FreqRange(k) -48;
    else
        mask(k) = -66;
    end
end
figure(1);hold on
plot(FreqRange, mask,'r','linewidth',2);hold on;grid on;
title('EDGE Modulation Spectrum, OSR=96')
xlabel('Frequency(Hz)');
ylabel('Power(dB)')
