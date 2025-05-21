% =========================================================================
% stability_analyze.m
% 工程背景：面向ASIC实现的高速IIR滤波器常用场景的工程实现性分析
% 目标：检验主流场景下主流IIR结构(Q2.22等)的可实现性与工程裕度，自动筛选可用方案。
% =========================================================================

clear; clc;

% --------- 场景配置（均为实际工程参考参数） ---------
scenarios = {
    % 名称           采样率     通带      阻带      通带波纹 阻带衰减 类型    主流结构 推荐位宽
    {'ADC抗混叠LP',   80e6,   15e6,   20e6,   0.5,  50, 'low',    'cheby2',  'Q2_22'}, % ADI/TI手册
    {'通信基带低通',   40e6,   6e6,    8e6,   0.5,  40, 'low',    'ellip',   'Q2_22'}, % LTE/5G前端
    {'宽带去噪LP',     48e6,   5e6,    8e6,   1.0,  40, 'low',    'cheby2',  'Q2_22'}, % 通信/雷达
    {'仪表低通LP',      2e6,   200e3,  350e3, 0.5,  50, 'low',    'ellip',   'Q2_22'}, % 仪表ADC
    {'基带高通HP',     20e6,   2e6,    0.8e6, 0.5,  35, 'high',   'cheby1',  'Q2_22'}, % 通信前端
    {'音频高通HP',     48e3,   3e3,    1.5e3, 0.2,  30, 'high',   'butter',  'Q1_14'}, % 音频
    {'IF带通BP',     61.44e6, [10e6,25e6], [8e6,27e6],1,40,'bandpass','ellip','Q2_22'}, % LTE中频
    {'5G中频BP',   122.88e6,[20.72e6,40.72e6],[18.72e6,42.72e6],1,40,'bandpass','ellip','Q2_22'} % 5G
};

bit_widths = struct('Q1_14', [16,14], 'Q2_22', [24,22]);
strict_margin = 0.93;
MAX_ORDER = 20;
EXTRA_STRUCTS = {'ellip','cheby2','cheby1','butter'};

fprintf('\n=== ASIC工程常见场景IIR类型定点可实现性分析 ===\n');

for si = 1:length(scenarios)
    s = scenarios{si};
    [name,Fs,Wp,Ws,Rp,Rs,type,main_struct,main_fp] = deal(s{:});
    binfo = bit_widths.(main_fp);
    fprintf('\n场景: %-14s | 采样率:%.2fMHz | 主流结构:%s | 推荐位宽:%s\n', ...
        name, Fs/1e6, main_struct, main_fp);
    if strcmp(type,'bandpass')
        fprintf('  通带:%.2f-%.2fMHz 阻带:%.2f-%.2fMHz\n',Wp(1)/1e6,Wp(2)/1e6,Ws(1)/1e6,Ws(2)/1e6);
        wp = Wp/(Fs/2); ws = Ws/(Fs/2); mode = 'bandpass';
    else
        fprintf('  %s: 通带%.2fMHz 阻带%.2fMHz\n', upper(type), Wp/1e6, Ws/1e6);
        wp = Wp/(Fs/2); ws = Ws/(Fs/2); mode = type;
    end
    if any(wp>=1)||any(ws>=1), continue; end
    structs2try = unique([{main_struct}, EXTRA_STRUCTS],'stable');
    for stype = 1:length(structs2try)
        try_struct = structs2try{stype};
        % === 1. 求理论最小阶 ===
        switch try_struct
            case 'ellip'
                [Nmin,Wn]=ellipord(wp,ws,Rp,Rs);
            case 'cheby1'
                [Nmin,Wn]=cheb1ord(wp,ws,Rp,Rs);
            case 'cheby2'
                [Nmin,Wn]=cheb2ord(wp,ws,Rp,Rs);
            case 'butter'
                [Nmin,Wn]=buttord(wp,ws,Rp,Rs);
            otherwise
                continue
        end
        tag = try_struct;
        found = false;
        % === 2. 从理论最小偶数阶起向上遍历 ===
        for N = 2*ceil(Nmin/2):2:MAX_ORDER
            try
                switch try_struct
                    case 'ellip'
                        [B,A]=ellip(N,Rp,Rs,Wn,mode);
                    case 'cheby1'
                        [B,A]=cheby1(N,Rp,Wn,mode);
                    case 'cheby2'
                        [B,A]=cheby2(N,Rs,Wn,mode);
                    case 'butter'
                        [B,A]=butter(N,Wn,mode);
                end
                [sos,g]=tf2sos(B,A);
                root_gain = g^(1/size(sos,1));
                for i=1:size(sos,1), sos(i,1:3) = sos(i,1:3)*root_gain; end
                sos_fixed = round(sos*2^binfo(2))/2^binfo(2);

                % 极点稳定性检测
                sysA = 1;
                for i=1:size(sos_fixed,1), sysA = conv(sysA, [1, sos_fixed(i,5:6)]); end
                poles = roots(sysA); maxpole = max(abs(poles));
                stable = isfinite(maxpole) && maxpole < strict_margin;
                margin = strict_margin - maxpole;

                % 累计误差
                [b1,a1]=sos2tf(sos_fixed,1);
                Nresp = 4096;
                h = impz(b1,a1,Nresp);
                step_resp = cumsum(h);
                if any(isnan(step_resp)) || any(isinf(step_resp)) || ~stable
                    accum_err = NaN;
                else
                    accum_err = max(abs(step_resp));
                end

                % 第一个满足条件的实现即采纳
                fprintf('  阶数:%2d | %s | 理论最小阶:%2d | 极点:%.4f %s 裕度:%.4f ', ...
                    N, tag, Nmin, maxpole, tf(stable), margin);
                if isnan(accum_err), fprintf('累计误差:失稳/无意义');
                else, fprintf('累计误差:%.2e', accum_err); end
                fprintf(' | 流水线级数:%2d', size(sos_fixed,1));
                if stable
                    found = true;
                    if strcmp(try_struct,main_struct)
                        fprintf(' 【主流结构推荐】\n');
                    else
                        fprintf(' （对比结构）\n');
                    end
                    break; % 找到第一个满足条件的实现即停止
                else
                    fprintf(' ⚠️ 失稳\n');
                end
            catch
                continue;
            end
        end
        if ~found
            fprintf('  %s 无稳定实现，建议放宽指标或提升位宽。\n', tag);
        end
    end
end

function s = tf(cond)
if cond, s='✅'; else, s='❌'; end
end