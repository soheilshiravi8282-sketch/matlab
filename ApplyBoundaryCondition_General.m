function fixedDOFs = ApplyBoundaryCondition_General(Mesh, Geometry, BC_code)

% =========================================================================
% اصلاح و تبدیل کدهای ۲ حرفی به ۴ حرفی
% =========================================================================
BC_code = char(BC_code);

% اگر ورودی ۲ حرفی بود (مانند SS یا CC)، آن را به ۴ حرفی (SSSS یا CCCC) تبدیل کن
if length(BC_code) == 2
    BC_code = [BC_code, BC_code];
elseif length(BC_code) ~= 4
    error('کد شرط مرزی باید ۲ حرفی (مانند SS) یا ۴ حرفی (مانند SSSS یا SFFC) باشد.');
end

% ... ادامه کدهای قبلی خودتان در ApplyBoundaryCondition_General ...
%==========================================================================
% ApplyBoundaryCondition_General
% BC_code: String of 4 characters, e.g., 'CFCF', 'CSFF', 'SCSF'
% Order of Edges: [Left (x=0), Right (x=a), Bottom (y=0), Top (y=b)]
%==========================================================================

nodes = Mesh.Node;
x = nodes(:, 1);
y = nodes(:, 2);
a = Geometry.a;
b = Geometry.b;

tol = 1e-6; % تلرانس شناسایی گره‌های مرزی

% استخراج گره‌های ۴ لبه
edgeNodes{1} = find(abs(x) < tol);         % لبه چپ   (x = 0)
edgeNodes{2} = find(abs(x - a) < tol);     % لبه راست  (x = a)
edgeNodes{3} = find(abs(y) < tol);         % لبه پایین (y = 0)
edgeNodes{4} = find(abs(y - b) < tol);     % لبه بالا   (y = b)

fixedDOFs = [];

for e = 1 : 4
    bcType = upper(BC_code(e));
    currNodes = edgeNodes{e};
    
    switch bcType
        case 'C' % Clamped (گیردار)
            % قید کردن w, theta_x, theta_y
            dofs = [3*currNodes - 2; 3*currNodes - 1; 3*currNodes];
            fixedDOFs = [fixedDOFs; dofs(:)];
            
        case 'S' % Simply Supported (تکیه‌گاه ساده)
            % فقط قید کردن خیز w
            dofs = 3*currNodes - 2;
            fixedDOFs = [fixedDOFs; dofs(:)];
            
        case 'F' % Free (آزاد)
            % هیچ درجه آزادی مقید نمی‌شود
            continue;
            
        otherwise
            error('نوع شرط مرزی "%s" تعریف نشده است. از C, S یا F استفاده کنید.', bcType);
    end
end

% حذف درجات آزادی تکراری در گوشه‌های ورق
fixedDOFs = unique(fixedDOFs);

end