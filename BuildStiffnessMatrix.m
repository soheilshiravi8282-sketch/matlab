function K = BuildStiffnessMatrix(Mesh, Material, Geometry)
% BuildStiffnessMatrix: مونتاژ ماتریس سختی کل با استفاده از ElementStiffness (MITC4)

nDOF = Mesh.nDOF;
K = zeros(nDOF, nDOF);

% حلقه روی تمام المان‌های مش
for e = 1:Mesh.nElement
    % استخراج شماره گره‌های المان e
    nodes = Mesh.Element(e, :);
    
    % استخراج مختصات x و y گره‌های المان
    coords = Mesh.Node(nodes, :); % ماتریس 4x2
    
    % محاسبه ماتریس سختی المان Q4 با تابع MITC4 شما
    Ke = ElementStiffness(coords, Material, Geometry);
    
    % یافتن درجات آزادی مربوط به این المان (در هر گره 3 درجه آزادی: w, theta_x, theta_y)
    elementDOFs = zeros(1, 12);
    for k = 1:4
        elementDOFs((k-1)*3 + (1:3)) = (nodes(k)-1)*3 + (1:3);
    end
    
    % مونتاژ در ماتریس سختی کل
    K(elementDOFs, elementDOFs) = K(elementDOFs, elementDOFs) + Ke;
end

end