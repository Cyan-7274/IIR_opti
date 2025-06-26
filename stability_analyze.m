% =========================================================================
% 工程实践级高速IIR典型场景批量筛选与稳定性分析 (Q2.14/16bit)
% =========================================================================
clear; clc;

% ========== 场景参数表 ==========
scenarios = [
    struct('name','ADC Anti-Aliasing','Fs',200e6,'Fp',60e6,'Fs_stop',80e6,'Rp',0.1,'Rs',70,'type','cheby1','min_order',8,'app','ADC前端'),
    struct('name','5G/LTE Baseband','Fs',122.88e6,'Fp',20e6,'Fs_stop',25e6,'Rp',0.1,'Rs',70,'type','cheby1','min_order',8,'app','5G/LTE基带'),
    struct('name','SDR Channelization','Fs',160e6,'Fp',40e6,'Fs_stop',50e6,'Rp',0.1,'Rs',70,'type','cheby1','min_order',8,'app','SDR信道化'),
    struct('name','Radar IF','Fs',100e6,'Fp',15e6,'Fs_stop',20e6,'Rp',0.1,'Rs',70,'type','cheby1','min_order',8,'app','雷达中频'),
    struct('name','GNSS Signal Processing','Fs',50e6,'Fp',10e6,'Fs_stop',13e6,'Rp',0.1,'Rs',60,'type','cheby1','min_order',8,'app','GNSS'),
    struct('name','Medical Ultrasound','Fs',40e6,'Fp',10e6,'Fs_stop',13e6,'Rp',0.1,'Rs',60,'type','cheby1','min_order',8,'app','超声'),
    struct('name','Industrial Control','Fs',100e6,'Fp',20e6,'Fs_stop',25e6,'Rp',0.1,'Rs',60,'type','cheby1','min_order',8,'app','工业'),
    struct('name','Scope Frontend','Fs',500e6,'Fp',150e6,'Fs_stop',200e6,'Rp',0.1,'Rs',70,'type','cheby1','min_order',8,'app','示波器'),
    struct('name','High-Speed Video','Fs',300e6,'Fp',100e6,'Fs_stop',120e6,'Rp',0.1,'Rs',70,'type','cheby1','min_order',8,'app','视频'),
    struct('name','HiFi Audio DSP','Fs',192e3,'Fp',40e3,'Fs_stop',50e3,'Rp',0.1,'Rs',60,'type','cheby1','min_order',8,'app','音频'),
    struct('name','Cable Modem Frontend','Fs',100e6,'Fp',20e6,'Fs_stop',25e6,'Rp',0.1,'Rs',60,'type','cheby1','min_order',8,'app','Cable Modem'),
    struct('name','WiFi 6/7 PHY','Fs',80e6,'Fp',20e6,'Fs_stop',25e6,'Rp',0.1,'Rs',50,'type','cheby1','min_order',8,'app','WiFi')
];

% ========== 定点参数 ==========
wl = 16; fl = 14;      % Q2.14
strict_margin = 0.96;  % 工程稳定裕度要求

fprintf('批量工程场景筛选（定点Q2.14 sos级联分析）\n');
fprintf('----------------------------------------------------------------------------------\n');
fprintf('%-22s %-6s %-7s %-7s %-7s %-7s %-7s %-7s %-9s %-8s %-8s\n', ...
    'name','阶数', 'Fs(M)', 'Fp(M)', 'Fs_stop', 'Rp', 'Rs', 'max|p|', '裕度', '稳定', '备注');
fprintf('----------------------------------------------------------------------------------\n');

for idx = 1:numel(scenarios)
    sc = scenarios(idx);
    % 设计滤波器
    Wpass = sc.Fp/(sc.Fs/2);
    Wstop = sc.Fs_stop/(sc.Fs/2);
    if strcmp(sc.type,'cheby1')
        [Nmin, Wn] = cheb1ord(Wpass, Wstop, sc.Rp, sc.Rs);
        N = max(sc.min_order, Nmin);
        [B, A] = cheby1(N, sc.Rp, Wn, 'low');
    else
        error('只支持cheby1');
    end
    [sos, g] = tf2sos(B, A);

    % 极点排序+均分增益
    sos_poles = zeros(size(sos,1), 1);
    for i = 1:size(sos,1)
        poles_i = roots([1, sos(i,5:6)]);
        sos_poles(i) = max(abs(poles_i));
    end
    [~, sort_idx] = sort(sos_poles, 'ascend');
    sos = sos(sort_idx, :);

    root_gain = g^(1/size(sos,1));
    for i = 1:size(sos,1)
        sos(i,1:3) = sos(i,1:3) * root_gain;
    end

    % 定点化
    scale = 2^fl;
    sos_fixed = round(sos * scale) / scale;

    % 工程级联极点分析
    sys_A = 1;
    for i = 1:size(sos_fixed,1)
        sys_A = conv(sys_A, [1, sos_fixed(i,5:6)]);
    end
    poles = roots(sys_A);
    max_pole_mag = max(abs(poles));
    stability_margin = strict_margin - max_pole_mag;
    is_stable = max_pole_mag < strict_margin;

    % 输出核心参数
    fprintf('%-22s %-6d %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.4f %-9.4f %-8s %-8s\n', ...
        sc.name, N, sc.Fs/1e6, sc.Fp/1e6, sc.Fs_stop/1e6, sc.Rp, sc.Rs, ...
        max_pole_mag, stability_margin, string(is_stable), sc.app);
end

fprintf('----------------------------------------------------------------------------------\n');
fprintf('工程实践下，推荐只选“稳定”=true的场景进行后续硬件实现和详细分析。\n');