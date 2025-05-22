
% 对比RTL仿真输出与Matlab定点参考输出
N = 2048;

% 读取Matlab定点参考输出
fid = fopen('D:/A_Hesper/IIRfilter/qts/sim/reference_output.hex','r');
y_ref_hex = textscan(fid, '%6s');
fclose(fid);
y_ref = hex2dec(char(y_ref_hex{1}));
% 补码还原为有符号
y_ref(y_ref >= 2^23) = y_ref(y_ref >= 2^23) - 2^24;
y_ref = double(y_ref) / 2^22; % Q2.22

% 读取RTL仿真输出
fid = fopen('D:/A_Hesper/IIRfilter/qts/sim/tb_dut_output.hex','r');
y_rtl_hex = textscan(fid, '%6s');
fclose(fid);
y_rtl = hex2dec(char(y_rtl_hex{1}));
y_rtl(y_rtl >= 2^23) = y_rtl(y_rtl >= 2^23) - 2^24;
y_rtl = double(y_rtl) / 2^22;

% 检查长度一致性，自动裁剪为最小长度
min_len = min(length(y_ref), length(y_rtl));
if length(y_ref) ~= length(y_rtl)
    warning('RTL输出与参考输出长度不一致，将自动裁剪对齐。');
end
y_ref = y_ref(1:min_len);
y_rtl = y_rtl(1:min_len);

% 对比绘图
figure;
subplot(2,1,1);
plot(y_ref, 'b'); hold on; plot(y_rtl, 'r--');
legend('Matlab定点参考','RTL仿真');
title('输出波形对比');
ylabel('幅度');

subplot(2,1,2);
plot(y_ref - y_rtl, 'k');
title('误差（Matlab定点-RTL）');
ylabel('误差'); xlabel('采样点');
fprintf('最大绝对误差：%g\n', max(abs(y_ref-y_rtl)));
fprintf('均方误差：%g\n', sqrt(mean((y_ref-y_rtl).^2)));