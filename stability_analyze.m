clear; clc;

% =========================================================================
% 高速IIR滤波器ASIC实现场景分析与优化工具 (优化版V2.0)
% 专注：技术挑战适中且工业代表性强的完美方案
% =========================================================================

% --------- 精选工业场景库（针对性优化版） ---------
scenarios = {
    % 场景名称                    采样率    通带频率  阻带频率   通带纹波 阻带衰减 类型      主流结构   位宽格式 稳定裕度
    
    %=== 数据采集系列（提升技术挑战） ===
    {'高速数据采集AA',            20e6,     6e6,     8.5e6,     0.1,    65,     'low',      'ellip',   'Q2_22', 0.94},
    {'精密测量采集',              15e6,     4.5e6,   6.5e6,     0.05,   70,     'low',      'cheby2',  'Q2_22', 0.93},
    {'示波器前端滤波',            25e6,     7.5e6,   10e6,      0.1,    60,     'low',      'ellip',   'Q2_22', 0.93},
    {'工业数据采集',              12e6,     3.6e6,   5.4e6,     0.1,    65,     'low',      'cheby2',  'Q2_22', 0.94},
    {'多通道采集系统',            18e6,     5.4e6,   7.2e6,     0.1,    70,     'low',      'ellip',   'Q2_22', 0.93},
    
    %=== 电力系统系列（增加复杂度） ===
    {'电网谐波分析仪',            16e6,     4.8e6,   6.4e6,     0.1,    75,     'low',      'ellip',   'Q2_22', 0.93},
    {'智能电网滤波',              20e6,     6e6,     8e6,       0.1,    70,     'low',      'cheby2',  'Q2_22', 0.94},
    {'电能质量监测',              12e6,     3.6e6,   4.8e6,     0.1,    80,     'low',      'ellip',   'Q2_22', 0.95},
    {'电力谐波抑制',              14e6,     4.2e6,   5.6e6,     0.1,    65,     'low',      'cheby2',  'Q2_22', 0.93},
    {'配电网滤波',                10e6,     3e6,     4.2e6,     0.1,    70,     'low',      'cheby2',  'Q2_22', 0.94},
    
    %=== 伺服控制系列（提升采样率） ===
    {'高精度伺服AA',              15e6,     4.5e6,   6e6,       0.1,    70,     'low',      'cheby2',  'Q2_22', 0.94},
    {'工业机器人控制',            18e6,     5.4e6,   7.2e6,     0.1,    65,     'low',      'ellip',   'Q2_22', 0.93},
    {'数控机床滤波',              22e6,     6.6e6,   8.8e6,     0.1,    70,     'low',      'cheby2',  'Q2_22', 0.93},
    {'伺服电机驱动',              12e6,     3.6e6,   4.8e6,     0.1,    75,     'low',      'ellip',   'Q2_22', 0.94},
    {'精密定位系统',              20e6,     6e6,     8e6,       0.1,    65,     'low',      'cheby2',  'Q2_22', 0.93},
    
    %=== 通信系统系列（经典应用） ===
    {'基带信号处理',              30.72e6,  9e6,     12e6,      0.2,    55,     'low',      'cheby1',  'Q2_22', 0.93},
    {'软件无线电',                25e6,     7.5e6,   10e6,      0.1,    60,     'low',      'ellip',   'Q2_22', 0.93},
    {'数字中频滤波',              40e6,     12e6,    16e6,      0.1,    65,     'low',      'ellip',   'Q2_22', 0.93},
    {'无线基站滤波',              15.36e6,  4.6e6,   6.1e6,     0.2,    60,     'low',      'cheby1',  'Q2_22', 0.94},
    {'通信抗混叠',                20e6,     6e6,     8e6,       0.1,    70,     'low',      'cheby2',  'Q2_22', 0.94},
    
    %=== 测试测量系列（高精度） ===
    {'频谱分析仪',                50e6,     15e6,    20e6,      0.05,   80,     'low',      'ellip',   'Q2_22', 0.93},
    {'信号分析仪',                40e6,     12e6,    16e6,      0.1,    75,     'low',      'ellip',   'Q2_22', 0.93},
    {'矢量分析仪',                30e6,     9e6,     12e6,      0.1,    70,     'low',      'cheby2',  'Q2_22', 0.94},
    {'精密仪器滤波',              25e6,     7.5e6,   10e6,      0.05,   85,     'low',      'ellip',   'Q2_22', 0.94},
    {'实验室测量',                35e6,     10.5e6,  14e6,      0.1,    75,     'low',      'ellip',   'Q2_22', 0.93},
    
    %=== 音视频系列（专业级） ===
    {'专业音频处理',              192e3,    80e3,    100e3,     0.05,   90,     'low',      'ellip',   'Q2_22', 0.95},
    {'数字音频工作站',            96e3,     40e3,    50e3,      0.05,   85,     'low',      'ellip',   'Q2_22', 0.96},
    {'视频信号处理',              27e6,     8.1e6,   10.8e6,    0.1,    60,     'low',      'cheby2',  'Q2_22', 0.94},
    {'广播级音频',                48e3,     20e3,    24e3,      0.05,   80,     'low',      'ellip',   'Q2_22', 0.95},
    
    %=== 医疗电子系列 ===
    {'医疗成像滤波',              20e6,     6e6,     8e6,       0.1,    70,     'low',      'cheby2',  'Q2_22', 0.94},
    {'生理信号处理',              10e6,     3e6,     4e6,       0.1,    75,     'low',      'ellip',   'Q2_22', 0.95},
    {'超声成像滤波',              40e6,     12e6,    16e6,      0.1,    65,     'low',      'ellip',   'Q2_22', 0.93},
    {'心电信号滤波',              8e6,      2.4e6,   3.2e6,     0.1,    80,     'low',      'cheby2',  'Q2_22', 0.95},
    
    %=== 雷达与军用系列 ===
    {'雷达信号处理',              60e6,     18e6,    24e6,      0.1,    70,     'low',      'ellip',   'Q2_22', 0.93},
    {'军用通信滤波',              50e6,     15e6,    20e6,      0.1,    75,     'low',      'ellip',   'Q2_22', 0.93},
    {'导航信号处理',              25e6,     7.5e6,   10e6,      0.1,    65,     'low',      'cheby2',  'Q2_22', 0.94},
    
    %=== 汽车电子系列 ===
    {'汽车雷达滤波',              24e6,     7.2e6,   9.6e6,     0.1,    60,     'low',      'cheby2',  'Q2_22', 0.94},
    {'CAN_FD信号处理',            8e6,      2.4e6,   3.2e6,     0.2,    50,     'low',      'butter',  'Q2_22', 0.94},
    {'车载导航滤波',              16e6,     4.8e6,   6.4e6,     0.1,    65,     'low',      'cheby2',  'Q2_22', 0.94},
    
    %=== 挑战性场景（高端应用） ===
    {'高速ADC后处理',             100e6,    30e6,    40e6,      0.1,    70,     'low',      'ellip',   'Q2_22', 0.93},
    {'宽带数字滤波',              80e6,     24e6,    32e6,      0.1,    65,     'low',      'ellip',   'Q2_22', 0.93},
    {'超高速数据处理',            120e6,    36e6,    48e6,      0.1,    75,     'low',      'ellip',   'Q2_22', 0.93}
};

% 定点化格式定义
bit_widths = struct('Q2_22', [24,22], 'Q3_21', [24,21], 'Q4_20', [24,20]);
MAX_ORDER = 20;
MIN_ORDER = 8;  % 提升最低阶数要求

% 时钟频率选项（MHz）
SYSTEM_CLOCKS = [80, 100, 120, 150, 200, 250, 300, 400, 500, 600];  % 提升最低时钟
STANDARD_LATENCY = 8;  % 标准设计延迟（时钟周期）
OPTIMIZED_LATENCY = 3; % 优化设计延迟（时钟周期）

fprintf('\n');
fprintf('=========================================================================\n');
fprintf('         高速IIR滤波器ASIC实现场景分析工具 (针对性优化版V2.0)\n');
fprintf('=========================================================================\n');
fprintf('目标：寻找技术挑战适中、工业代表性强、优化效果显著的完美方案\n');
fprintf('要求：≥8阶，优化余量提升≥30%%，工业应用广泛，有明确标准\n\n');

results = [];
valid_count = 0;

for si = 1:length(scenarios)
    s = scenarios{si};
    [name,Fs,Wp,Ws,Rp,Rs,ftype,filter_struct,bit_format,margin] = deal(s{:});
    binfo = bit_widths.(bit_format);
    
    fprintf('场景%2d: %-20s | %7.2fMHz | %8s | 裕度:%.2f\n', ...
        si, name, Fs/1e6, filter_struct, margin);
    
    % === 1. 频率归一化与有效性检查 ===
    if strcmp(ftype,'bandpass')
        wp = Wp/(Fs/2); ws = Ws/(Fs/2);
        if any(wp>=0.95) || any(ws>=0.95) || any(wp<=0.05) || min(diff(wp))<0.1
            fprintf('        ❌ 带通频率设置不合理\n');
            continue;
        end
    else
        wp = Wp/(Fs/2); ws = Ws/(Fs/2);
        if wp>=0.9 || ws>=0.95 || wp<=0.05 || (ws-wp)<0.1
            fprintf('        ❌ 频率归一化超限或过渡带过窄\n');
            continue;
        end
    end
    
    % === 2. 时序可行性预分析 ===
    sample_period_ns = 1e9/Fs;
    feasible_clks = [];
    standard_feasible = [];
    
    for clk_mhz = SYSTEM_CLOCKS
        clk_period_ns = 1000/clk_mhz;
        standard_time = STANDARD_LATENCY * clk_period_ns;
        optimized_time = OPTIMIZED_LATENCY * clk_period_ns;
        
        % 标准版可行性
        if standard_time <= sample_period_ns * 1.1  % 允许10%超时
            standard_feasible = [standard_feasible, clk_mhz];
        end
        
        % 优化版可行性  
        if optimized_time <= sample_period_ns * 0.8  % 预留20%余量
            feasible_clks = [feasible_clks, clk_mhz];
        end
    end
    
    if isempty(feasible_clks)
        fprintf('        ❌ 优化版时序不可行\n');
        continue;
    end
    
    % === 3. 滤波器阶数估算与设计 ===
    try
        switch filter_struct
            case 'ellip'
                [Nmin,Wn] = ellipord(wp,ws,Rp,Rs);
            case 'cheby1'
                [Nmin,Wn] = cheb1ord(wp,ws,Rp,Rs);
            case 'cheby2'
                [Nmin,Wn] = cheb2ord(wp,ws,Rp,Rs);
            case 'butter'
                [Nmin,Wn] = buttord(wp,ws,Rp,Rs);
        end
    catch ME
        fprintf('        ❌ 滤波器设计失败\n');
        continue;
    end
    
    % === 4. 寻找最优阶数实现 ===
    best_solution = [];
    start_order = max(MIN_ORDER, 2*ceil(Nmin/2));
    
    for N = start_order:2:MAX_ORDER
        try
            % 设计滤波器
            switch filter_struct
                case 'ellip'
                    [B,A] = ellip(N,Rp,Rs,Wn,ftype);
                case 'cheby1'
                    [B,A] = cheby1(N,Rp,Wn,ftype);
                case 'cheby2'
                    [B,A] = cheby2(N,Rs,Wn,ftype);
                case 'butter'
                    [B,A] = butter(N,Wn,ftype);
            end
            
            % 转换为SOS并优化排序
            [sos,g] = tf2sos(B,A);
            if isempty(sos), continue; end
            
            % 增益分配优化
            root_gain = g^(1/size(sos,1));
            for i = 1:size(sos,1)
                sos(i,1:3) = sos(i,1:3) * root_gain;
            end
            
            % SOS节排序优化（按Q值升序）
            if size(sos,1) > 1
                q_factors = zeros(size(sos,1),1);
                for i = 1:size(sos,1)
                    poles = roots([1, sos(i,5:6)]);
                    if length(poles) == 2 && ~isreal(poles(1))
                        q_factors(i) = 0.5/abs(real(poles(1)));
                    else
                        q_factors(i) = 0.1;
                    end
                end
                [~,sort_idx] = sort(q_factors);
                sos = sos(sort_idx,:);
            end
            
            % === 5. 定点化处理与验证 ===
            sos_fixed = round(sos * 2^binfo(2)) / 2^binfo(2);
            
            % 系数范围检查
            max_coeff = max(abs(sos_fixed(:)));
            coeff_range = 2^(binfo(1)-binfo(2)-1);
            if max_coeff >= coeff_range, continue; end
            
            % 稳定性分析
            sys_poles = [];
            for i = 1:size(sos_fixed,1)
                section_poles = roots([1, sos_fixed(i,5:6)]);
                sys_poles = [sys_poles; section_poles];
            end
            
            max_pole_mag = max(abs(sys_poles));
            stability_margin = margin - max_pole_mag;
            
            if ~isfinite(max_pole_mag) || max_pole_mag >= margin, continue; end
            
            % === 6. 性能验证 ===
            try
                [b_total,a_total] = sos2tf(sos_fixed,1);
                h = impz(b_total, a_total, 512);
                if any(~isfinite(h)), continue; end
                
                % 频率响应验证
                [H,w] = freqz(b_total, a_total, 1024);
                H_mag_db = 20*log10(abs(H));
                
                % 量化噪声估算
                coeff_noise_var = (2^(-2*binfo(2)))/12 * sum(sos_fixed(:).^2);
                snr_est = -10*log10(coeff_noise_var);
                
            catch
                continue;
            end
            
            % === 7. 时序性能计算 ===
            num_sections = size(sos_fixed,1);
            min_clk = feasible_clks(1);
            clk_period_ns = 1000/min_clk;
            
            standard_proc_time = STANDARD_LATENCY * clk_period_ns;
            optimized_proc_time = OPTIMIZED_LATENCY * clk_period_ns;
            
            standard_margin = (sample_period_ns - standard_proc_time) / sample_period_ns * 100;
            optimized_margin = (sample_period_ns - optimized_proc_time) / sample_period_ns * 100;
            
            % 优化提升幅度
            optimization_gain = optimized_margin - standard_margin;
            
            % === 8. 毕设适用性评分 ===
            % 新的评分标准，重点考虑毕设需求
            
            % 技术挑战度 (25%): 8-12阶最佳，过高过低都减分
            challenge_score = 0;
            if N >= 8 && N <= 12
                challenge_score = 100 * (1 - abs(N-10)/10);  % 10阶最佳
            elseif N > 12
                challenge_score = max(0, 100 - (N-12)*10);   % 超过12阶递减
            else
                challenge_score = N * 10;  % 低于8阶线性减分
            end
            
            % 优化效果 (35%): 优化提升幅度越大越好
            if optimization_gain >= 30
                optimization_score = min(100, optimization_gain * 2);
            else
                optimization_score = optimization_gain;  % 低于30%的提升不理想
            end
            
            % 工业应用度 (25%): 根据应用领域评分
            industry_score = 60;  % 基础分
            if contains(name, {'数据采集', '伺服', '电力', '通信', '测试', '仪器'})
                industry_score = 90;
            elseif contains(name, {'高速', '精密', '专业'})
                industry_score = 80;
            end
            
            % 实现可行性 (15%): 稳定裕度和时序余量
            feasibility_score = min(100, stability_margin*1000 + optimized_margin);
            
            % 综合评分
            total_score = (challenge_score * 0.25 + optimization_score * 0.35 + ...
                          industry_score * 0.25 + feasibility_score * 0.15);
            
            % 筛选条件：必须满足毕设基本要求
            meets_requirements = (N >= 8) && (optimization_gain >= 25) && ...
                                (optimized_margin >= 40) && (stability_margin > 0.01);
            
            if meets_requirements && (isempty(best_solution) || total_score > best_solution.score)
                best_solution = struct(...
                    'order', N, 'sections', num_sections, 'sos', sos_fixed, ...
                    'max_pole', max_pole_mag, 'stability_margin', stability_margin, ...
                    'min_clk', min_clk, 'standard_margin', standard_margin, ...
                    'optimized_margin', optimized_margin, 'optimization_gain', optimization_gain, ...
                    'snr_est', snr_est, 'score', total_score, 'max_coeff', max_coeff, ...
                    'challenge_score', challenge_score, 'optimization_score', optimization_score, ...
                    'industry_score', industry_score, 'feasibility_score', feasibility_score);
            end
            
        catch ME
            continue;
        end
    end
    
    % === 9. 结果记录 ===
    if ~isempty(best_solution)
        fprintf(['        ✅ %s %2d阶 | 极点:%.4f | 裕度:%.4f | %d节SOS | %dMHz\n' ...
                 '           标准:%5.1f%% → 优化:%5.1f%% | 提升:%5.1f%% | 评分:%.1f\n'], ...
            filter_struct, best_solution.order, best_solution.max_pole, ...
            best_solution.stability_margin, best_solution.sections, best_solution.min_clk, ...
            best_solution.standard_margin, best_solution.optimized_margin, ...
            best_solution.optimization_gain, best_solution.score);
        
        % 添加到结果集
        result = struct();
        result.name = name;
        result.fs_mhz = Fs/1e6;
        result.filter_type = filter_struct;
        result.order = best_solution.order;
        result.sections = best_solution.sections;
        result.max_pole = best_solution.max_pole;
        result.stability_margin = best_solution.stability_margin;
        result.min_sys_clk = best_solution.min_clk;
        result.standard_margin = best_solution.standard_margin;
        result.optimized_margin = best_solution.optimized_margin;
        result.optimization_gain = best_solution.optimization_gain;
        result.snr_estimate = best_solution.snr_est;
        result.total_score = best_solution.score;
        result.challenge_score = best_solution.challenge_score;
        result.optimization_score = best_solution.optimization_score;
        result.industry_score = best_solution.industry_score;
        result.sos_coeffs = best_solution.sos;
        
        results = [results; result];
        valid_count = valid_count + 1;
        
    else
        fprintf('        ❌ 无法满足毕设要求（≥8阶，优化提升≥25%%）\n');
    end
end

% =========================================================================
% 结果汇总与推荐
% =========================================================================
if ~isempty(results)
    fprintf('\n');
    fprintf('=========================================================================\n');
    fprintf('                      完美毕设方案汇总（Top15）\n');
    fprintf('=========================================================================\n');
    fprintf('%-20s | 采样率 | 结构     | 阶数 | 时钟 | 标准→优化 | 提升 | 评分\n', '场景名称');
    fprintf('%s\n', repmat('-', 1, 95));
    
    % 按综合评分排序
    [~, idx] = sort([results.total_score], 'descend');
    sorted_results = results(idx);
    
    for i = 1:min(length(sorted_results), 15)
        r = sorted_results(i);
        fprintf('%-20s | %6.1fMHz | %-8s | %2d阶 | %3dMHz | %5.1f%%→%5.1f%% | %5.1f%% | %5.1f\n', ...
            r.name, r.fs_mhz, r.filter_type, r.order, r.min_sys_clk, ...
            r.standard_margin, r.optimized_margin, r.optimization_gain, r.total_score);
    end
    
    % === 推荐最佳方案 ===
    best = sorted_results(1);
    second = sorted_results(2);
    third = sorted_results(3);
    
    fprintf('\n');
    fprintf('🏆🏆🏆 毕设完美方案 - TOP 3 🏆🏆🏆\n');
    fprintf('=========================================================================\n');
    
    for rank = 1:3
        if rank <= length(sorted_results)
            r = sorted_results(rank);
            
            fprintf('\n🥇 第%d名: %s\n', rank, r.name);
            fprintf('采样频率: %.1f MHz | %s %d阶 (%d节SOS)\n', ...
                r.fs_mhz, r.filter_type, r.order, r.sections);
            fprintf('系统时钟: %d MHz\n', r.min_sys_clk);
            fprintf('时序性能: 标准版%.1f%% → 优化版%.1f%% (提升%.1f%%)\n', ...
                r.standard_margin, r.optimized_margin, r.optimization_gain);
            fprintf('稳定裕度: %.4f | SNR: %.1fdB | 综合评分: %.1f\n', ...
                r.stability_margin, r.snr_estimate, r.total_score);
            
            % 分项评分
            fprintf('评分详情: 挑战度%.1f | 优化效果%.1f | 工业应用%.1f | 可行性%.1f\n', ...
                r.challenge_score, r.optimization_score, r.industry_score, ...
                (r.stability_margin*1000 + r.optimized_margin));
        end
    end
    
    % 最佳方案的SOS系数
    fprintf('\n🔧 推荐方案SOS系数 (%s):\n', best.name);
    fprintf('节 |      b0      |      b1      |      b2      |      a1      |      a2\n');
    fprintf('%s\n', repmat('-', 1, 75));
    for i = 1:size(best.sos_coeffs,1)
        fprintf('%2d | %12.8f | %12.8f | %12.8f | %12.8f | %12.8f\n', ...
            i, best.sos_coeffs(i,:));
    end
    
    fprintf('\n💡 实现建议:\n');
    fprintf('✅ 完美匹配毕设需求：≥8阶，优化提升≥25%%，工业应用广泛\n');
    fprintf('✅ 建议系统时钟: %d-%d MHz (预留设计余量)\n', best.min_sys_clk, round(best.min_sys_clk*1.5));
    fprintf('✅ 采用直接II型转置结构，SOS级联流水线设计\n');
    fprintf('✅ 标准版: Booth-4 + Wallace树乘法器，8拍延迟\n');
    fprintf('✅ 优化版: Booth-4 + Wallace + CLA，3拍延迟\n');
    fprintf('✅ 优化效果显著：处理能力提升%.1f%%，实时性大幅改善\n', best.optimization_gain);
    
    fprintf('\n📊 方案对比分析:\n');
    fprintf('场景          | 采样率  | 阶数 | 优化提升 | 工业应用度 | 推荐度\n');
    fprintf('------------- | ------- | ---- | -------- | ---------- | ------\n');
    for i = 1:min(3, length(sorted_results))
        r = sorted_results(i);
        app_level = '中等';
        if r.industry_score >= 85, app_level = '高'; 
        elseif r.industry_score <= 70, app_level = '低'; end
        
        recommend = '⭐⭐⭐';
        if i == 2, recommend = '⭐⭐'; 
        elseif i == 3, recommend = '⭐'; end
        
        fprintf('%-13s | %6.1fMHz | %2d阶 | %7.1f%% | %10s | %6s\n', ...
            r.name(1:min(13,end)), r.fs_mhz, r.order, r.optimization_gain, app_level, recommend);
    end
    
    fprintf('\n🎯 最终建议:\n');
    fprintf('基于技术挑战适中、优化效果显著、工业应用广泛的综合考虑,\n');
    fprintf('强烈推荐选择【%s】作为毕设实现对象。\n', best.name);
    fprintf('该方案在满足≥8阶技术要求的同时，提供了%.1f%%的显著优化提升，\n', best.optimization_gain);
    fprintf('具有明确的工业标准和广泛的实际应用，完美契合毕设展示需求。\n');
    
    fprintf('\n总计: %d个场景通过严格筛选，前3名均为优质毕设选择。\n', valid_count);
    
else
    fprintf('\n❌ 没有场景满足严格的毕设要求\n');
    fprintf('建议: 适当调整最低阶数要求或优化提升阈值\n');
end

fprintf('\n=========================================================================\n');
fprintf('                    针对性优化分析完成\n');
fprintf('=========================================================================\n');
