function Element = ElementConnectivity(nx, ny)
%==========================================================
% Q4 Element Connectivity
%
% Node ordering (Counter-clockwise):
%
% 4 (Top-Left) -------- 3 (Top-Right)
% |                      |
% |                      |
% 1 (Bottom-Left) ------ 2 (Bottom-Right)
%
%==========================================================
Element = zeros(nx*ny, 4);
e = 0;

for j = 1:ny
    for i = 1:nx
        e = e + 1;
        
        % محاسبه نمایه گره‌ها بر اساس شبکه‌بندی سطر-به-سطر
        n1 = (j-1)*(nx+1) + i;      % Bottom-Left  (گره ۱)
        n2 = n1 + 1;                % Bottom-Right (گره ۲)
        n4 = j*(nx+1) + i;          % Top-Left     (گره ۴)
        n3 = n4 + 1;                % Top-Right    (گره ۳)
        
        % تنظیم اتصال‌دهی پادپادساعتگرد
        Element(e,:) = [n1 n2 n3 n4];
    end
end
end