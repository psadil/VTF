%looking to see what jitter does to efficiency in TR's of 4s
 
addpath /Users/jeanettemumford/Documents/Research/matlabcode/  
%edit the above path to point towards the directory with spm_hrf in it.
 
 
 
%before we get to the code, let's draw a picture.  Our goal is to have a
%design with a stimulus followed by a response.  The stimulus will be 2s
%long, followed by a 4s fixation and a 2s response and a 4s fixation.  Let's draw a time line
%of our paradigm
 
 
 
 
%How much time passes from the beginning of one stimulus to the beginning
%of the next stimulus?
 
%12s
 
 
 
%If the first stimulus is at 1s, when are the rest of the stimuli?
 
% 1, 13, ... [1:12:200]
 
 
 
%when would the response cue occur?
 
% 7, 19  [1:12:200]+ 2 + 4 
 
 
 
% How many stimuli can we fit into one 200s long run?
 
% 16
 
 
%create each trial in high resolution, convolve and then I'll downsample to
%a TR of TR second
%set up the hrf info
TR=2;
 
t=0:0.25:200;
hrf_25=spm_hrf(0.25);
 
%onset times for first task (in s)
%What should the onset times for the first stimulus be?
 
t1=[1:12:200];
r1=zeros(1, 801);  %I'm assuming time resoultion of .25 s, so this corresponds to 200 2s TRs
for i=1:length(t1)
    r1(t1(i)<=t & t<=(t1(i)+2))=1;  %add 2 for a 2s trial
end
 
r1=conv(hrf_25, r1);
r1=r1(1:4*TR:800);
 
t_tr=t(1:4*TR:800);  %this is time in seconds (for plotting purposes)
 
% set up the second task, first with exactly a 4 second delay 
% (so add 6s since first task is 2s).
 
r2=zeros(1, 801);
t2=t1+2+4;  
 
 
for i=1:length(t2)
    r2(t2(i)<=t & t<=(t2(i)+2))=1;  %add 2 for a 2s trial
end
 
r2=conv(hrf_25, r2);
r2=r2(1:4*TR:800);
 
r1=r1-mean(r1);
r2=r2-mean(r2);
 
 
plot(t_tr, r1)
hold on
plot(t_tr, r2, 'g')
hold off
 
%efficiency for each regressor, the difference and all together
X=[r1', r2'];
c1=[1 0];
c2=[0 1];
 
eff1=1./(c1*inv(X'*X)*c1');
 
eff2=1./(c2*inv(X'*X)*c2');
 
 
 
eff_all=2./(c1*inv(X'*X)*c1'+c2*inv(X'*X)*c2');
 
eff1
eff2
 
eff_all
 
 
 
%--------------------------------------------------------------------------
%Let's make a different design with jitter.  We will leave r1 the same
 
%Uniform distribution between 0& 1: randomly select numbers between 0 and 1.  Mean of
%U(0,1) is 0.5, mean of U(1,4) is (4+1)/2, mean of U(2,6) is (6+2)/2=8
 
 
 
%here's the setup, let's keep the first fixation 4s on average and the
%second 4s on average. If the minimum fixation is 1s long, What uniform
%distribution range should we use for an average duration of 4s?
 
 
%U(1,7) Note this is U(0,1)*6 + 1
 
 
%Do I need to generate 2 random uniform things, or just 1.  Note, I want to
%keep the stimulus times the same.
 
 
 
%Don't forget the duration of the stimulus is 2s long, so we need to add
%that to our Uniform distribution.
 
 
 %rand generates random numbers from a continous uniform dist.
t2b=t1+2+rand(size(t1))*6+1;
 
r2b=zeros(1, 801);
   
for i=1:length(t2b)
  r2b(t2b(i)<=t & t<=(t2b(i)+2))=1;  %add 2 for a 2s trial
end
 
r2b=conv(hrf_25, r2b);
r2b=r2b(1:4*TR:800);
r2b=r2b-mean(r2b);
    
     
     
%plot the top designs
 
subplot(2,1,1)
plot(t_tr, r1, 'linewidth', 2)
hold on
plot(t_tr, r2, 'g', 'linewidth', 2)
hold off
xlabel('Time (s)')
title('Fixed time = 4s', 'Fontsize', 14)
 
subplot(2,1,2)
plot(t_tr, r1, 'linewidth', 2)
hold on
plot(t_tr, r2b, 'g', 'linewidth', 2)
hold off
xlabel('Time (s)')
title('Random time between 1 and 7 s', 'Fontsize', 14)
 
%compare the efficiences of the 2 designs
Xb=[r1', r2b'];
 
eff1b=1./(c1*inv(Xb'*Xb)*c1');
 
eff2b=1./(c2*inv(Xb'*Xb)*c2');
 
eff_allb=2./(c1*inv(Xb'*Xb)*c1'+c2*inv(Xb'*Xb)*c2');
 
fprintf('c1:  Jittered efficiency=%g     Fixed efficiency=%g \n', eff1b, eff1) 
fprintf('c2:  Jittered efficiency=%g     Fixed efficiency=%g \n', eff2b, eff2)
 
fprintf('all:  Jittered efficiency=%g     Fixed efficiency=%g \n', eff_allb, eff_all)
corr(r1', r2')
corr(r1', r2b')
 
 
nsim=100;
eff_save_1=zeros(nsim, 1);
eff_save_2=zeros(nsim,1);
 
for j=1:nsim
     %rand generates random numbers from a continous uniform dist.
    t2b=t1+2+rand(size(t1))*6+1;
 
    r2b=zeros(1, 801);
   
    for i=1:length(t2b)
      r2b(t2b(i)<=t & t<=(t2b(i)+2))=1;  %add 2 for a 2s trial
    end
    r2b=conv(hrf_25, r2b);
    r2b=r2b(1:4*TR:800);
    r2b=r2b-mean(r2b);
    Xb=[r1', r2b'];
    eff_save_1(j,1)=1./(c1*inv(Xb'*Xb)*c1');
    eff_save_2(j,1)=1./(c2*inv(Xb'*Xb)*c2');
end
 
subplot(1,1,1)
plot(eff_save_1, eff_save_2, '.')
 
 
%% FYI, here's how you properly code up a truncated exponential
 
n = 1000000;
lambda = 5.12;    % This is the parameter on your exponential
T = 5;            % This is the largest duration allowed
 
% Here's the mean of the truncated exponential
lambda - T*(exp(T/lambda)-1)^(-1)
  
R = rand(n,1)*(1-exp(-T/lambda));
rand_isi = -log(1-R)*lambda;
 
mean(rand_isi)