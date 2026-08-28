function F = BuildLoadVector(Mesh, Geometry, Load)
% BuildLoadVector: تشکیل بردار بارگذاری کل برای ورق Q4 تحت بار گسترده یکنواخت

nDOF = Mesh.nDOF;
F = zeros(nDOF, 1);

q = Load.q; % مقدار بار گسترده (N/m^2)

% نقاط و اوزان انتگرال‌گیری گوس ۲x۲
gp = [-1/sqrt(3), 1/sqrt(3)];
w  = [1, 1];

for e = 1:Mesh.nElement
    nodes  = Mesh.Element(e, :);
    coords = Mesh.Node(nodes, :); % مختصات ۴ گره المان [4x2]
    
    Fe = zeros(12, 1); % ۱۲ درجه آزادی برای هر المان Q4
    
    for i = 1:2
        for j = 1:2
            xi  = gp(i);
            eta = gp(j);
            wt  = w(i) * w(j);
            
            % توابع شکل المان ۴ گرهی
            N = 0.25 * [
                (1-xi)*(1-eta);
                (1+xi)*(1-eta);
                (1+xi)*(1+eta);
                (1-xi)*(1+eta)
            ];
            
            % مشتق توابع شکل نسبت به ایزوپارامتری
            dN_dxi  = 0.25 * [-(1-eta);  (1-eta); (1+eta); -(1+eta)];
            dN_deta = 0.25 * [-(1-xi);  -(1+xi);  (1+xi);   (1-xi)];
            
            % ژاکوبی و دترمینان آن
            J = [dN_dxi'; dN_deta'] * coords;
            detJ = det(J);
            
            % تشکیل بردار توابع شکل برای درجات آزادی المان (بار فقط روی w اثر می‌گذارد)
            N_mat = zeros(1, 12);
            for k = 1:4
                N_mat(1, (k-1)*3 + 1) = N(k);
            end
            
            % انتگرال‌گیری گوس برای بردار بار المان
            Fe = Fe + N_mat' * q * detJ * wt;
        end
    end
    
    % مونتاژ بردار بار المان در بردار بار کل F
    elementDOFs = zeros(1, 12);
    for k = 1:4
        elementDOFs((k-1)*3 + (1:3)) = (nodes(k)-1)*3 + (1:3);
    end
    
    F(elementDOFs) = F(elementDOFs) + Fe;
end

end