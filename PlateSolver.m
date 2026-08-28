function Result = PlateSolver(Mesh, Material, Geometry, Load, BC)

% =========================================================================
% تعیین هوشمند درجات آزادی مقید (fixedDOFs)
% =========================================================================
if isnumeric(BC)
    % اگر ورودی از جنس آرایه عددی باشد (مانند fixedDOFs)
    fixedDOFs = BC;
    BC_Name   = 'Custom';
elseif ischar(BC) || isstring(BC)
    % اگر ورودی کد متنی ۴ حرفی باشد (مانند 'SSSS', 'SFFC', 'CFFF')
    BC_Name   = char(BC);
    fixedDOFs = ApplyBoundaryCondition_General(Mesh, Geometry, BC_Name);
else
    error('فرمت شرط مرزی ورودی نامعتبر است.');
end

fprintf('Solving %s plate...\n', BC_Name);

% =========================================================================
% استخراج درجات آزادی آزاد و حل دستگاه
% =========================================================================
totalDOFs = Mesh.nDOF;
freeDOFs  = setdiff(1:totalDOFs, fixedDOFs);

% تشکیل ماتریس سختی K و بردار بار F (توابع موجود در کد خودتان)
K = BuildStiffnessMatrix(Mesh, Material, Geometry);
F = BuildLoadVector(Mesh, Geometry, Load);

% حل دستگاه تقلیل‌یافته
u = zeros(totalDOFs, 1);
u(freeDOFs) = K(freeDOFs, freeDOFs) \ F(freeDOFs);

% استخراج خیز و محاسبه ضریب غیربعدی C
w = u(1:3:end); % درجات آزادی خیز (w)
wmax = max(abs(w));

D = (Material.E * Geometry.h^3) / (12 * (1 - Material.nu^2));
C_FEM = (wmax * D) / (Load.q * Geometry.a^4);

% خروجی ساختار Result
Result.w     = w;
Result.wmax  = wmax;
Result.C_FEM = C_FEM;
Result.u     = u;

end