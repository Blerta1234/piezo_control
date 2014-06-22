%% First Attempt to Control

clear acc
clear t

total_t = 20;
actuate_t = 10;

%% Arrays
T = 0.03;
N = floor(total_t / T) + 30;
t = zeros(N,1);
t_act = zeros(N,1);
acc = zeros(N,1);
dummy = zeros(N,2);
act = zeros(N,1);
g  = zeros(size(t));
gf = zeros(size(t));
v  = zeros(size(t));
x  = zeros(size(t));
vf = zeros(size(t));
xf = zeros(size(t));
K = 1000;

%% Profiling

read_time    = zeros(size(t));
process_time = zeros(size(t));
actuate_time = zeros(size(t));

%%

enable_pin  = 10;
dir_pin     = 7;

f = 3;      % [Hz]
prev = 0;

%% Filters
alpha_low = 0.2;
lp = @(y,x) (alpha_low*y + (1-alpha_low)*x);
alpha_high = 0.1;
hp = @(y,x_1,x_2) ((1-alpha_high)*y + (1-alpha_high)*(x_1 - x_2));
d  = @(x,x2) -(x-x2);

%% Start
a.roundTrip(0,0);

cut_off = [0.15 0.15 0.15]; % [xf vf gf]
g_cut_off = 0.1;

%% Controller
k = -1e2;
z = -0.999;
p = -0.8607;
delta_time = 5;
Kx = 0;
Kv = 5e2;
Kg = 0;
l  = 0.1;
n_samples = 2;
i = n_samples + 1;
tic
elapsed_time = toc;
while (elapsed_time < total_t)
    elapsed_time = toc;
    if (prev + T < elapsed_time) || abs(prev + T - elapsed_time) < 1e-4
        t(i) = elapsed_time;
        acc(i) = a.sample();
%         dummy(i,1) = a.analogRead(0);
%         dummy(i,2) = a.analogRead(1);
%         read_time(i) = toc - elapsed_time;
        g(i)   = n_to_g(3,acc(i));
        prev = elapsed_time;
        %% Signal Processing
        v(i) = d(g(i),g(i-1));
        vf(i) = lp(vf(i-1),v(i));
        x(i) = -g(i);
        if any(abs([x(i) vf(i) g(i)]) > cut_off) && true
            act(i) = -[Kx Kv Kg]*[x(i) vf(i) g(i)]';
            [n,dir] = V_to_N(act(i));
            a.roundTrip(dir,n);
        end
        i = i + 1;
    end
end

a.roundTrip(0,0);
%%
run = Run(T,t,acc,[x v g]',act);
run.store();
%%

% run.plot(3,[5 3])

%%

r = DSP.nm_rms(run.g)
damping = DSP.get_damping(run.T,run.t,run.g)
% DSP.plot_exp(run.T,run.t,run.g)
