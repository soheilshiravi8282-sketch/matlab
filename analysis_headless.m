function outStruct = analysis_headless(p)
% ANALYSIS_HEADLESS  Runs the plate FEM analysis without any UI.
% Input p (struct, typically decoded from JSON) must contain fields:
%   a, b, h, mesh, E1, E2, nu12, G12, bc   (bc is one of 'SS','CC','SCSC','CFFF')
% Output outStruct (struct, ready for jsonencode) contains:
%   X, Y, W   -> 2D grids (as nested arrays) for 3D plotting
%   C_FE, wmax, D, status -> scalars/text for the report panel

    % ---- Build Geometry ----
    Geometry.a = p.a;
    Geometry.b = p.b;
    Geometry.h = p.h;
    nelx = p.mesh;
    nely = nelx;

    % ---- Build Material ----
    Material.Name = 'Custom_Material';
    Material.E1   = p.E1 * 1e9;
    Material.E2   = p.E2 * 1e9;
    Material.nu12 = p.nu12;
    Material.G12  = p.G12 * 1e9;
    Material.E    = Material.E1;
    Material.nu   = Material.nu12;

    % ---- Build Mesh (suppress the verification figure FEMesh pops up) ----
    figsBefore = findall(0, 'Type', 'figure');
    if exist('FEMesh', 'file') == 2
        Mesh = FEMesh(Geometry, nelx, nely);
    else
        Mesh = local_mesh_fallback(Geometry, nelx, nely);
    end
    figsAfter = findall(0, 'Type', 'figure');
    newFigs = setdiff(figsAfter, figsBefore);
    if ~isempty(newFigs)
        close(newFigs);   % close the mesh-verification figure, headless mode
    end

    % ---- Load ----
    Load.Type = 'STATIC';
    Load.q = 1000;

    % ---- Solve ----
    bcCode = p.bc;
    if strcmp(bcCode, 'SSSS'), bcCode = 'SS'; end
    if strcmp(bcCode, 'CCCC'), bcCode = 'CC'; end

    Result = PlateSolver(Mesh, Material, Geometry, Load, bcCode);

    maxW = Result.wmax;
    C_FE = Result.C_FEM;
    D    = (Material.E * Geometry.h^3) / (12 * (1 - Material.nu^2));

    % ---- Reshape into 2D grid for surface plotting ----
    nx = round(sqrt(Mesh.nNode));
    ny = nx;
    X = reshape(Mesh.Node(:,1), nx, ny);
    Y = reshape(Mesh.Node(:,2), nx, ny);
    W = reshape(Result.w, nx, ny);

    % ---- Pack output for JSON ----
    outStruct.X = X;
    outStruct.Y = Y;
    outStruct.W = W;
    outStruct.C_FE = C_FE;
    outStruct.wmax = maxW;
    outStruct.D = D;
    outStruct.bc = bcCode;
    outStruct.status = 'ok';
end

function Mesh = local_mesh_fallback(Geo, nelx, nely)
    nx = nelx + 1;
    ny = nely + 1;
    [X, Y] = meshgrid(linspace(0, Geo.a, nx), linspace(0, Geo.b, ny));
    Mesh.Node = [X(:), Y(:)];
    Mesh.nNode = size(Mesh.Node, 1);
    Mesh.nElement = nelx * nely;
    Mesh.nDOF = Mesh.nNode * 3;
end
