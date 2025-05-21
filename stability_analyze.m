clear; clc;

% 场景配置(主流+适合Chebyshev II型的典型场景)
scenarios = {
    % 名称         采样率    通带        阻带         通带波纹 阻带衰减   类型      主流结构   推荐位宽
    {'通信基带低通', 40e6,   6e6,    8e6,     0.5,  40,  'low',      'ellip',   'Q2_22'}, ...
    {'高速ADC LP',   80e6,   15e6,   19e6,    0.5,  50,  'low',      'cheby2',  'Q2_22'}, ... % Chebyshev II型应用
    {'IF带通',       61.44e6, [10e6,25e6], [8e6,27e6],1,40,'bandpass','ellip',   'Q2_22'}, ...
    {'5G中频BP',     122.88e6,[20.72e6,40.72e6],[18.72e6,42.72e6],1,50,'bandpass','ellip','Q2_22'}, ...
    {'宽带LP',       80e6,    12e6,    15e6,    1,  40,  'low',      'ellip',   'Q2_22'}, ...
    {'仪表低通',     1e6,     30e3,    40e3,    0.5,60,  'low',      'ellip',   'Q1_14'}, ...
    {'音频高通',     48e3,    3e3,     1.5e3,   0.2,35,  'high',     'butter',  'Q1_14'}, ...
    {'宽带高通',     40e6,    10e6,    8e6,     1,  40,  'high',     'ellip',   'Q2_22'}, ...
    {'ADC抗混叠LP',  100e6,   20e6,    25e6,    0.5,60,  'low',      'cheby2',  'Q2_22'}, ... % Chebyshev II型常用
};

bit_widths = struct('Q1_14', [16,14], 'Q2_22', [24,22]);
strict_margin = 0.93;
test_orders = [8, 12, 16, 20]; % 可加10,14,18阶

extra_structs = {'cheby1','cheby2','butter'}; % 对比结构

fprintf('\n=== ASIC工程常见场景下主流结构与Chebyshev II型的定点滤波可实现性 ===\n');

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

    structs2try = unique([{main_struct}, extra_structs],'stable');
    for ord = test_orders
        for stype = 1:length(structs2try)
            try_struct = structs2try{stype};
            try
                switch try_struct
                    case 'ellip'
                        [N,Wn]=ellipord(wp,ws,Rp,Rs); N=max(ord,N);
                        [B,A]=ellip(N,Rp,Rs,Wn,mode);
                        tag = '椭圆型';
                    case 'cheby1'
                        [N,Wn]=cheb1ord(wp,ws,Rp,Rs); N=max(ord,N);
                        [B,A]=cheby1(N,Rp,Wn,mode);
                        tag = '切比雪夫I';
                    case 'cheby2'
                        [N,Wn]=cheb2ord(wp,ws,Rp,Rs); N=max(ord,N);
                        [B,A]=cheby2(N,Rs,Wn,mode);
                        tag = '切比雪夫II';
                    case 'butter'
                        [N,Wn]=buttord(wp,ws,Rp,Rs); N=max(ord,N);
                        [B,A]=butter(N,Wn,mode);
                        tag = '巴特沃斯型';
                    otherwise
                        continue
                end
                [sos,g]=tf2sos(B,A);
                root_gain = g^(1/size(sos,1));
                for i=1:size(sos,1), sos(i,1:3) = sos(i,1:3)*root_gain; end
                sos_fixed = round(sos*2^binfo(2))/2^binfo(2);

                % 稳定性与累计误差
                sysA = 1;
                for i=1:size(sos_fixed,1), sysA = conv(sysA, [1, sos_fixed(i,5:6)]); end
                poles = roots(sysA); maxpole = max(abs(poles));
                stable = isfinite(maxpole) && maxpole < strict_margin; margin = strict_margin - maxpole;

                % 累计误差分析
                [b1,a1]=sos2tf(sos_fixed,1);
                Nresp = 4096;
                h = impz(b1,a1,Nresp);
                step_resp = cumsum(h);
                if any(isnan(step_resp)) || any(isinf(step_resp)) || ~stable
                    accum_err = NaN; % 失稳无需累计误差
                else
                    accum_err = max(abs(step_resp));
                end
            catch
                maxpole=NaN; stable=false; margin=NaN; accum_err=NaN; tag = try_struct;
            end
            fprintf('  阶数:%2d | %s | 极点:%.4f %s 裕度:%.4f ', ...
                ord, tag, maxpole, tf(stable), margin);
            fprintf('累计误差:');
            if isnan(accum_err)
                fprintf('失稳/无意义');
            else
                fprintf('%.2e', accum_err);
            end
            fprintf(' | 流水线级数:%2d', size(sos_fixed,1));
            if stable
                if strcmp(try_struct,main_struct)
                    fprintf(' 【主流结构推荐】\n');
                else
                    fprintf(' （对比结构）\n');
                end
            else
                fprintf(' ⚠️ 失稳\n');
            end
        end
    end
end

function s = tf(cond)
if cond, s='✅'; else, s='❌'; end
end