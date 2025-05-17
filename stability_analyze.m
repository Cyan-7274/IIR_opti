clear
clc
%% 场景参数
scenarios = {
    {'IF带通',          61.44e6, [10e6,25e6], [8e6,27e6], 1, 40, 'bandpass'}, ...
    {'基带低通',        40e6,    5e6,         8e6,        0.5, 40, 'low'}, ...
    {'高速ADC低通',     80e6,    10e6,        15e6,       1, 40,  'low'}, ...
    {'音频高通',        48e3,    4e3,         2e3,        0.2, 35, 'high'},...
    {'5G基站中频带通', 122.88e6, [20.72e6, 40.72e6], [18.72e6, 42.72e6], 1, 50, 'bandpass'}, ...
    {'通信基带低通', 10e6, 1e6, 1.5e6, 1, 40, 'low'}, ...
    {'音频低通', 48e3, 8e3, 10e3, 0.1, 40, 'low'}, ...
    {'数字信号宽带低通',40e6, 8e6, 12e6, 0.5, 35, 'low'}, ...
    {'通用高通', 10e6, 2e6, 1e6, 1, 40, 'high'},...
    {'中频带通(实验)', 61.44e6, [15e6, 35e6], [12e6, 38e6], 1, 40, 'bandpass'}
};
fixed_point = {16, 14, 'Q1.14'};
strict_margin = 0.93;

fprintf('\n=== 椭圆型转置型(SOS) vs 切比雪夫I型直接型(SOS) vs 巴特沃斯型(SOS) 多场景对比 ===\n');
for si = 1:length(scenarios)
    s = scenarios{si};
    [name,Fs,Wp,Ws,Rp,Rs,type] = deal(s{:});
    fprintf('\n场景: %-8s | 采样率:%.2fMHz | ', name, Fs/1e6);
    if strcmp(type,'bandpass')
        fprintf('通带:%.2f-%.2fMHz 阻带:%.2f-%.2fMHz\n',Wp(1)/1e6,Wp(2)/1e6,Ws(1)/1e6,Ws(2)/1e6);
        wp = Wp/(Fs/2); ws = Ws/(Fs/2); mode = 'bandpass';
    else
        fprintf('%s: 通带%.2fMHz 阻带%.2fMHz\n', upper(type), Wp/1e6, Ws/1e6);
        wp = Wp/(Fs/2); ws = Ws/(Fs/2); mode = type;
    end
    if any(wp>=1)||any(ws>=1), fprintf('  ⚠️ 归一化频率超限，跳过\n'); continue; end

    % 椭圆型
    try
        [N1,Wn1]=ellipord(wp,ws,Rp,Rs);
        [B1,A1]=ellip(N1,Rp,Rs,Wn1,mode);
        [sos1,g1]=tf2sos(B1,A1);
        root_gain = g1^(1/size(sos1,1));
        for i=1:size(sos1,1)
            sos1(i,1:3) = sos1(i,1:3)*root_gain;
        end
        sos1_fixed = round(sos1*2^fixed_point{2})/2^fixed_point{2};
        sysA1 = 1;
        for i=1:size(sos1_fixed,1)
            sysA1 = conv(sysA1, [1, sos1_fixed(i,5:6)]);
        end
        poles1 = roots(sysA1); maxpole1 = max(abs(poles1));
        stable1 = maxpole1 < strict_margin;
    catch
        N1 = -1; maxpole1 = NaN; stable1=false;
    end

    % 切比雪夫I型
    try
        [N2,Wn2]=cheb1ord(wp,ws,Rp,Rs);
        [B2,A2]=cheby1(N2,Rp,Wn2,mode);
        [sos2,g2]=tf2sos(B2,A2);
        root_gain2 = g2^(1/size(sos2,1));
        for i=1:size(sos2,1)
            sos2(i,1:3) = sos2(i,1:3)*root_gain2;
        end
        sos2_fixed = round(sos2*2^fixed_point{2})/2^fixed_point{2};
        sysA2 = 1;
        for i=1:size(sos2_fixed,1)
            sysA2 = conv(sysA2, [1, sos2_fixed(i,5:6)]);
        end
        poles2 = roots(sysA2); maxpole2 = max(abs(poles2));
        stable2 = maxpole2 < strict_margin;
    catch
        N2 = -1; maxpole2 = NaN; stable2=false;
    end

    % 巴特沃斯型
    try
        [N3,Wn3]=buttord(wp,ws,Rp,Rs);
        [B3,A3]=butter(N3,Wn3,mode);
        [sos3,g3]=tf2sos(B3,A3);
        root_gain3 = g3^(1/size(sos3,1));
        for i=1:size(sos3,1)
            sos3(i,1:3) = sos3(i,1:3)*root_gain3;
        end
        sos3_fixed = round(sos3*2^fixed_point{2})/2^fixed_point{2};
        sysA3 = 1;
        for i=1:size(sos3_fixed,1)
            sysA3 = conv(sysA3, [1, sos3_fixed(i,5:6)]);
        end
        poles3 = roots(sysA3); maxpole3 = max(abs(poles3));
        stable3 = maxpole3 < strict_margin;
    catch
        N3 = -1; maxpole3 = NaN; stable3=false;
    end

    fprintf(['对比: [椭圆型] 阶:%d 极点:%.4f %s | [切比雪夫I型] 阶:%d 极点:%.4f %s | [巴特沃斯型] 阶:%d 极点:%.4f %s\n'],...
        N1, maxpole1, tf(stable1), N2, maxpole2, tf(stable2), N3, maxpole3, tf(stable3));
    if stable1
        fprintf('  -> 推荐: 椭圆型, Q1.14, 阶数低, 稳定性好\n');
        fprintf('  比巴特沃斯减少阶数: %d\n', N3-N1);
        fprintf('  椭圆型Q1.14系数:\n');
        disp(sos1_fixed(:,[1 2 3 5 6]));
    elseif stable2
        fprintf('  -> 推荐: 切比雪夫I型, Q1.14\n');
        fprintf('  比巴特沃斯减少阶数: %d\n', N3-N2);
        fprintf('  切比雪夫I型Q1.14系数:\n');
        disp(sos2_fixed(:,[1 2 3 5 6]));
    elseif stable3
        fprintf('  -> 推荐: 巴特沃斯型, Q1.14\n');
        fprintf('  巴特沃斯Q1.14系数:\n');
        disp(sos3_fixed(:,[1 2 3 5 6]));
    else
        fprintf('  -> 建议: 提高定点位宽或放宽指标\n');
    end
end

function s = tf(cond)
if cond, s='✅'; else, s='❌'; end
end