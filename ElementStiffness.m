function Ke = ElementStiffness(coords, Material, Geometry)
%==========================================================
% ElementStiffness: Q4 Mindlin plate element (FSDT)
% Compatible with Isotropic and Composite Laminates (MITC4)
%
% DOF per node: [w, theta_x, theta_y]
%==========================================================

%% ۱. تعیین ماتریس‌های رفتار ماده (خمشی Db و برشی Ds)
if isfield(Material, 'D') && isfield(Material, 'As')
    % حالت کامپوزیت چندلایه (استفاده از ماتریس‌های D و As محاسبه‌شده)
    Db = Material.D;
    Ds = Material.As;
else
    % حالت ایزوتروپ تک‌لایه
    E  = Material.E;
    nu = Material.nu;
    h  = Geometry.h;
    
    Db = (E*h^3 / (12*(1-nu^2))) * [
        1       nu      0;
        nu      1       0;
        0       0       (1-nu)/2
    ];
    
    Gs    = E / (2*(1+nu));
    kappa = 5/6;
    Ds    = kappa * Gs * h * eye(2);
end

%% ۲. مقداردهی اولیه
Ke = zeros(12, 12);
gp = [-1/sqrt(3), 1/sqrt(3)]; % نقاط انتگرال‌گیری گوس ۲x۲

%% ۳. محاسبه ماتریس سفتگری خمشی (Bending Stiffness)
for i = 1:2
    for j = 1:2
        xi  = gp(i);
        eta = gp(j);
        
        [~, dN, detJ] = ShapeData(xi, eta, coords);
        
        Bb = zeros(3, 12);
        for a = 1:4
            idx = (a-1)*3 + 1;
            Bb(:, idx:idx+2) = [
                0          dN(1,a)      0;
                0             0       dN(2,a);
                0          dN(2,a)   dN(1,a)
            ];
        end
        
        Ke = Ke + Bb' * Db * Bb * detJ;
    end
end

%% ۴. نقطه اتصال MITC4 برای کرنش‌های برشی (Shear Tying Points)
% Tying Point A: (xi=0, eta=-1)
[N_A, dN_A, ~] = ShapeData(0, -1, coords);
Bxm = zeros(1, 12);
for a = 1:4
    idx = (a-1)*3 + 1;
    Bxm(1, idx:idx+2) = [dN_A(1,a), N_A(a), 0];
end

% Tying Point C: (xi=0, eta=+1)
[N_C, dN_C, ~] = ShapeData(0, 1, coords);
Bxp = zeros(1, 12);
for a = 1:4
    idx = (a-1)*3 + 1;
    Bxp(1, idx:idx+2) = [dN_C(1,a), N_C(a), 0];
end

% Tying Point D: (xi=-1, eta=0)
[N_D, dN_D, ~] = ShapeData(-1, 0, coords);
Bym = zeros(1, 12);
for a = 1:4
    idx = (a-1)*3 + 1;
    Bym(1, idx:idx+2) = [dN_D(2,a), 0, N_D(a)];
end

% Tying Point B: (xi=+1, eta=0)
[N_B, dN_B, ~] = ShapeData(1, 0, coords);
Byp = zeros(1, 12);
for a = 1:4
    idx = (a-1)*3 + 1;
    Byp(1, idx:idx+2) = [dN_B(2,a), 0, N_B(a)];
end

%% ۵. محاسبه ماتریس سفتگری برشی (MITC4 Shear Integration)
for i = 1:2
    for j = 1:2
        xi  = gp(i);
        eta = gp(j);
        
        [~, ~, detJ] = ShapeData(xi, eta, coords);
        
        Bs = zeros(2, 12);
        % درون‌یابی کرنش برشی gamma_xz در امتداد eta
        Bs(1, :) = 0.5*(1-eta)*Bxm + 0.5*(1+eta)*Bxp;
        % درون‌یابی کرنش برشی gamma_yz در امتداد xi
        Bs(2, :) = 0.5*(1-xi)*Bym  + 0.5*(1+xi)*Byp;
        
        Ke = Ke + Bs' * Ds * Bs * detJ;
    end
end

end

%% ========================================================================
%% توابع محلی: توابع شکل و ژاکوبین
%% ========================================================================
function [N, dN, detJ] = ShapeData(xi, eta, coords)
N = 0.25 * [
    (1-xi)*(1-eta);
    (1+xi)*(1-eta);
    (1+xi)*(1+eta);
    (1-xi)*(1+eta)
];

dN_dxi = 0.25 * [
    -(1-eta);
     (1-eta);
     (1+eta);
    -(1+eta)
];

dN_deta = 0.25 * [
    -(1-xi);
    -(1+xi);
     (1+xi);
     (1-xi)
];

J = [dN_dxi'; dN_deta'] * coords;
detJ = det(J);

if detJ <= 0
    error('Jacobian determinant is non-positive. Check element connectivity.');
end

dN = J \ [dN_dxi'; dN_deta'];
end