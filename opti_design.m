%% 高速IIR滤波器设计与分析工具 v3.1 (支持RTL自动对齐)
% 重点功能：
% 1. 节点按极点模值排序，输出原始序号排序表
% 2. 按排序后最后一节合入整体增益g，输出所有节点定点化后的Q格式系数表
% 3. 输出适合直接粘贴进Verilog的硬编码整数表（含原始序号注释）
% 4. 修正所有struct赋值，避免非法字段名

clear; clc;
fprintf('====================================================\n');
fprintf('       高速IIR滤波器设计与分析工具 v3.1            \n');
fprintf('====================================================\n\n');

%% Step 1: 滤波器参数
filter_type = 'bandpass';
Fs = 122.88e6;
Fp1 = 20.72e6; Fp2 = 40.72e6;
Fs1 = 18.72e6; Fs2 = 42.72e6;
Wp = [Fp1 Fp2]/(Fs/2);
Ws = [Fs1 Fs2]/(Fs/2);
Rp = 1; Rs = 50;
fprintf('采样频率: %.2f MHz\n', Fs/1e6);
fprintf('通带: %.2f-%.2f MHz 阻带: <%.2f, >%.2f MHz\n', Fp1/1e6,Fp2/1e6,Fs1/1e6,Fs2/1e6);
fprintf('通带纹波: %.1f dB, 阻带衰减: %.1f dB\n', Rp, Rs);

%% Step 2: 滤波器设计
[N, Wn] = ellipord(Wp, Ws, Rp, Rs);
[B, A] = ellip(N, Rp, Rs, Wn, filter_type);
[sos, g] = tf2sos(B, A);
fprintf('\n阶数: %d, SOS节点数: %d, 初始增益g: %.10f\n', N, size(sos,1), g);

%% Step 3: 极点模值排序
N_sections = size(sos,1);
pole_mags = zeros(N_sections,1);
for i=1:N_sections
    a_sec = [1 sos(i,5:6)];
    poles = roots(a_sec);
    pole_mags(i) = max(abs(poles));
end
[~, sort_idx] = sort(pole_mags, 'descend');
sorted_sos = sos(sort_idx,:);

fprintf('\n===== 节点排序结果(原始节点号) =====\n');
for i=1:N_sections
    fprintf('排序后第%d节 ← 原始节点%d, 极点模值=%.10f\n', i, sort_idx(i), max(abs(roots([1 sos(sort_idx(i),5:6)]))));
end

%% Step 4: 定点化+增益分配
word_length = 16; frac_length = 14;
scale_factor = 2^frac_length;
fprintf('\n===== Q格式定点化系数表(Q2.14, 以整数形式输出，适合Verilog硬编码) =====\n');
fprintf('// 排序后节点编号, 原始节点号, b0, b1, b2, a1, a2\n');
fixed_coeffs = zeros(N_sections,5); % 存储输出

for i = 1:N_sections
    coeffs = sorted_sos(i,1:5);
    % 只对排序后最后一节合入增益g
    if i==N_sections
        coeffs = coeffs * g;
    end
    % Q格式量化
    q_coeffs = round(coeffs*scale_factor);
    fixed_coeffs(i,:) = q_coeffs;
    fprintf('%% 节点%d (原始%d)\n', i, sort_idx(i));
    fprintf('%d, %d, %d, %d, %d, %d\n', i-1, q_coeffs(1), q_coeffs(2), q_coeffs(3), q_coeffs(4), q_coeffs(5));
end

%% Step 5: 输出Verilog case代码片段建议
fprintf('\n// 建议Verilog case片段如下:\n');
for i = 1:N_sections
    fprintf('// 排序后第%d节（原始节点%d）\n', i, sort_idx(i));
    fprintf('3d%d: begin\n', i-1);
    fprintf('    b0_reg = 16h%s;\n', dec2hex(typecast(int16(fixed_coeffs(i,1)),'uint16'),4));
    fprintf('    b1_reg = 16h%s;\n', dec2hex(typecast(int16(fixed_coeffs(i,2)),'uint16'),4));
    fprintf('    b2_reg = 16h%s;\n', dec2hex(typecast(int16(fixed_coeffs(i,3)),'uint16'),4));
    fprintf('    a1_reg = 16h%s;\n', dec2hex(typecast(int16(fixed_coeffs(i,4)),'uint16'),4));
    fprintf('    a2_reg = 16h%s;\n', dec2hex(typecast(int16(fixed_coeffs(i,5)),'uint16'),4));
    fprintf('end\n');
end

%% Step 6: 完整输出Q格式浮点值（便于查验）
fprintf('\n// Q2.14格式下浮点值表(便于软件模型或查验):\n');
for i = 1:N_sections
    coeffs = double(fixed_coeffs(i,:))/scale_factor;
    fprintf('%% 节点%d (原始%d): ', i, sort_idx(i));
    fprintf('b0=%.8f, b1=%.8f, b2=%.8f, a1=%.8f, a2=%.8f\n', coeffs(1), coeffs(2), coeffs(3), coeffs(4), coeffs(5));
end

%% 友情提示
fprintf('\n// RTL请严格按此排序和Q整数表硬编码，最后一节系数已乘以g，不再单独做增益校正。\n');

%% 策略分析结构体字段名修正范例
strategy_keys = {'gain_last', 'gain_even', 'gain_separate'};
strategy_names = {'集中增益到最后节点', '均匀分布到所有节点', '独立增益系数'};
strategy_results = struct();

% for i = 1:length(strategy_keys)
%     key = strategy_keys{i};
%     name = strategy_names{i};
%     % ...分析逻辑...
%     stable = true; % 这里只是示例
%     if stable
%         strategy_results.(key) = 'stable';
%     else
%         strategy_results.(key) = 'unstable';
%     end
% end
% 
% fprintf('\n===== 总结与最优策略选择 =====\n');
% for i = 1:length(strategy_keys)
%     fprintf('%s: %s\n', strategy_names{i}, strategy_results.(strategy_keys{i}));
% end