function Mesh = FEMesh(Geometry, nx, ny)
%==========================================================
% Q4 Finite Element Mesh
% Thin Plate Validation
%==========================================================
a = Geometry.a;
b = Geometry.b;

%% Node coordinates
x = linspace(0, a, nx+1);
y = linspace(0, b, ny+1);
[X, Y] = meshgrid(x, y);

% ترانهاده کردن برای شماره‌گذاری سطر-به-سطر (چپ به راست، پایین به بالا)
X = X';
Y = Y';

Mesh.Node = [X(:), Y(:)];
Mesh.nNode = size(Mesh.Node, 1);

%% Element connectivity
Mesh.Element = ElementConnectivity(nx, ny);
Mesh.nElement = size(Mesh.Element, 1);

%% Degrees of freedom
Mesh.DOFPerNode = 3; % [w0, theta_x, theta_y]
Mesh.dofPerNode = 3; % جهت هماهنگی کامل با توابع شرایط مرزی
Mesh.nDOF = Mesh.nNode * Mesh.DOFPerNode;

%% Mesh Information & Visualization
Mesh.nx = nx;
Mesh.ny = ny;

figure('Name', 'Q4 Mesh Verification', 'NumberTitle', 'off');
hold on;
grid on;
axis equal;

for e = 1:Mesh.nElement
    nodes = Mesh.Element(e,:);
    coord = Mesh.Node(nodes,:);
    
    % رسم اضلاع المان
    plot([coord(:,1); coord(1,1)], ...
         [coord(:,2); coord(1,2)], 'k-', 'LineWidth', 0.8);
end

plot(Mesh.Node(:,1), Mesh.Node(:,2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 4);
title(['Q4 Plate Mesh (', num2str(nx), 'x', num2str(ny), ' Elements)']);
xlabel('x (m)');
ylabel('y (m)');
box on;

end