function out=MMregcore(y,X,b0,auxscale,varargin)
%MMregcore computes MM regression estimators for a selected fixed scale.
%
%<a href="matlab: docsearchFS('MMregcore')">Link to the help function</a>
%
%  Required input arguments:
%
%    y: Response variable. Vector. A vector with n elements that contains
%       the response variable. y can be either a row or a column vector.
%    X: Data matrix of explanatory variables (also called 'regressors') of
%       dimension (n x p-1). Rows of X represent observations, and columns
%       represent variables.
%       Missing values (NaN's) and infinite values (Inf's) are allowed,
%       since observations (rows) with missing or infinite values will
%       automatically be excluded from the computations.
%    b0:        Initial estimate of beta. Vector. Vector containing initial
%               estimate of beta (generally an S estimate with high
%               breakdown point (e.g. 0.5).
% auxscale:     scale estimate. Scalar.
%               Scalar containing estimate of the scale (generally an S
%               estimate with high breakdown point (e.g. .5)).
%
%  Optional input arguments:
%
%    intercept :  Indicator for constant term. true (default) | false.
%                 Indicator for the constant term (intercept) in the fit,
%                 specified as the comma-separated pair consisting of
%                 'Intercept' and either true to include or false to remove
%                 the constant term from the model.
%                 Example - 'intercept',false
%                 Data Types - boolean
%
%      eff     : nominal efficiency. Scalar.
%                Scalar defining nominal efficiency (i.e. a number between
%                 0.5 and 0.99). The default value is 0.95
%                 Asymptotic nominal efficiency is:
%                 $(\int \psi' d\Phi)^2 / (\psi^2 d\Phi)$
%                 Example - 'eff',0.99
%                 Data Types - double
%
%     effshape : location or scale efficiency. dummy scalar.
%                If effshape=1 efficiency refers to shape
%                efficiency, else (default) efficiency refers to location.
%                 Example - 'effshape',1
%                 Data Types - double
%
%     refsteps  : Maximum iterations. Scalar.
%                 Scalar defining maximum number of iterations in the MM
%                 loop. Default value is 100.
%                 Example - 'refsteps',10
%                 Data Types - double
%
%      reftol: Tolerance. Scalar.
%                 Scalar controlling tolerance in the MM loop.
%                 Default value is 1e-7
%                 Example - 'tol',1e-10
%                 Data Types - double
%
%     conflev :  Confidence level which is
%               used to declare units as outliers. Scalar.
%               Usually conflev=0.95, 0.975 0.99 (individual alpha)
%               or 1-0.05/n, 1-0.025/n, 1-0.01/n (simultaneous alpha).
%               Default value is 0.975
%                 Example - 'conflev',0.99
%                 Data Types - double
%
%     rhofunc : rho function. String. String which specifies the rho
%               function which must be used to weight the residuals.
%               Possible values are:
%               'bisquare';
%               'optimal';
%               'hyperbolic';
%               'hampel';
%               'mdpd'.
%               'AS'.
%               'bisquare' uses Tukey's $\rho$ and $\psi$ functions.
%               See TBrho and TBpsi.
%               'optimal' uses optimal $\rho$ and $\psi$ functions.
%               See OPTrho and OPTpsi.
%               'hyperbolic' uses hyperbolic $\rho$ and $\psi$ functions.
%               See HYPrho and HYPpsi.
%               'hampel' uses Hampel $\rho$ and $\psi$ functions.
%               See HArho and HApsi.
%               'mdpd' uses Minimum Density Power Divergence $\rho$ and $\psi$ functions.
%               See PDrho.m and PDpsi.m.
%               'AS' uses  Andrew's sine $\rho$ and $\psi$ functions.
%               See ASrho.m and ASpsi.m.
%               The default is bisquare.
%                 Example - 'rhofunc','optimal'
%                 Data Types - char
%
% rhofuncparam: Additional parameters for the specified rho function.
%               Scalar or vector or empty value.
%               For hyperbolic rho function it is possible to set up the
%               value of k = sup CVC (the default value of k is 4.5).
%               For Hampel rho function it is possible to define parameters
%               a, b and c (the default values are a=2, b=4, c=8). For the
%               other rho functions (Tuhey, PD and optimal), it is an empty
%               value.
%                 Example - 'rhofuncparam',5
%                 Data Types - single | double
%
%       nocheck : Check input arguments. Boolean. If nocheck is equal to
%               true, no check is performed on matrix y and matrix X. Notice
%               that y and X are left unchanged. In other words, the
%               additional column of ones for the intercept is not added.
%               As default nocheck=false.
%               Example - 'nocheck',true
%               Data Types - boolean
%
%       plots : Plot on the screen. Scalar or structure.
%               If plots = 1, generates a plot with the robust residuals
%               against index number. The confidence level used to draw the
%               confidence bands for the residuals is given by the input
%               option conflev. If conflev is not specified, a nominal 0.975
%               confidence interval will be used.
%                 Example - 'plots',0
%                 Data Types - single | double
%
%       yxsave : the response vector y and data matrix X are saved into the output
%                structure out. Scalar.
%               Default is 0, i.e. no saving is done.
%               Example - 'yxsave',1
%               Data Types - double
%
%  Output:
%
%      out :     A structure containing the following fields
%
%       out.beta  = p x 1 vector. Estimate of beta coefficients after
%                   refsteps refining steps.
%   out.residuals = n x 1 vector containing the estimates of the robust
%                   scaled residuals.
%   out.outliers  = A vector containing the list of the units declared as
%                   outliers using confidence level specified in input
%                   scalar conflev.
%   out.conflev   = Confidence level that was used to declare outliers.
%   out.weights   = n x 1 vector. Weights assigned to each observation.
%     out.rhofunc = string identifying the rho function which has been
%                   used.
% out.rhofuncparam= vector which contains the additional parameters
%                   for the specified rho function that have been
%                   used. For hyperbolic rho function the value of
%                   k =sup CVC. For Hampel rho function the parameters
%                   a, b and c. This field is empty if rhofunc is not
%                   'hampel' or 'hyperbolic'.
%     out.y       = response vector y. The field is present only if option
%                   yxsave is set to 1.
%     out.X       = data matrix X. The field is present only if option
%                   yxsave is set to 1.
%     out.class   = 'MMreg'
%
%
% More About:
%
% It does iterative reweighted least squares (IRWLS) steps from "initial
% beta" (b0) keeping the estimate of the scale (auxscale) fixed.
%
% See also: Sreg
%
% References:
%
% Maronna, R.A., Martin D. and Yohai V.J. (2006), "Robust Statistics, Theory
% and Methods", Wiley, New York.
%
% Acknowledgements:
%
% This function follows the lines of MATLAB/R code developed during the
% years by many authors.
% For more details see the R library robustbase 
% http://robustbase.r-forge.r-project.org/.
% The core of these routines, e.g. the resampling approach, however, has
% been completely redesigned, with considerable increase of the
% computational performance.
%
% Copyright 2008-2025.
% Written by FSDA team
%
%
%<a href="matlab: docsearchFS('MMregcore')">Link to the help page for this function</a>
%
%$LastChangedDate::                      $: Date of the last commit

% Examples:
%
%{
    % MMregcore with all default options.
    n=200;
    p=3;
    state1=123456;
    randn('state', state1);
    X=randn(n,p);
    y=randn(n,1);
    kk=10;
    ycont = y;
    ycont(1:kk)=ycont(1:kk)+7;
    [outS]=Sreg(ycont,X);
    outMM=MMregcore(ycont,X,outS.beta,outS.scale)
%}

%{
    %% MMregcore with optional input arguments.
    % Determine, e.g., an S estimate and extract the required arguments for the MM estimate.
    n=200;
    p=3;
    state1=123456;
    randn('state', state1);
    X=randn(n,p);
    y=randn(n,1);
    kk=10;
    ycont = y;
    ycont(1:kk)=ycont(1:kk)+7;
    [outS]=Sreg(ycont,X);
    out=MMregcore(ycont,X,outS.beta,outS.scale,'plots',1)
%}

%{
    % Weighting the residuals with a rho function.
    % Determine, e.g., an S estimate and extract the required arguments for the MM estimate.
    % This time use a Tukey biweight for S estimation and HA rho function
    % for MM loop.
    n=200;
    p=3;
    state1=123456;
    randn('state', state1);
    X=randn(n,p);
    y=randn(n,1);
    kk=10;
    ycont = y;
    ycont(1:kk)=ycont(1:kk)+7;
    [outS]=Sreg(ycont,X);
    rhofunc='hampel';
    outMM1=MMregcore(ycont,X,outS.beta,outS.scale,'rhofunc',rhofunc,'plots',1)
%}

%{
    % Comparison between direct call to MMreg and call to Sreg and MMregcore.
    % In this example, two different rho functions are used for S and MM.
    n=30;
    p=3;
    randn('state', 16);
    X=randn(n,p);
    % Uncontaminated data
    y=randn(n,1);
    % Contaminated data
    ycont=y;
    ycont(1:5)=ycont(1:5)+6;
    % Two different rho functions are used for S and MM
    rhofuncS='hyperbolic';
    rhofuncMM='hampel';
    % Direct call to MMreg
    [out]=MMreg(ycont,X,'Srhofunc',rhofuncS,'rhofunc',rhofuncMM,'Snsamp',0);

    % Call to Sreg and then to MMregcore
    [outS]=Sreg(ycont,X,'rhofunc',rhofuncS,'nsamp',0);
    outMM=MMregcore(ycont,X,outS.beta,outS.scale,'rhofunc',rhofuncMM);
    disp('Difference between direct call to S and the calls to Sreg and MMregcore')
    max(abs([out.beta-outMM.beta]))
%}

%% Beginning of code

nnargin = nargin;
vvarargin = varargin;
[y,X,n] = aux.chkinputR(y,X,nnargin,vvarargin);

% default nominal efficiency
effdef = 0.95;
% by default the nominal efficiency refers to location efficiency
effshapedef = 0;
% default value of number of maximum refining iterations
refstepsdef = 100;
% default value of tolerance for the refining steps convergence
reftoldef = 1e-7;
% rho (psi) function which has to be used to weight the residuals
rhofuncdef='bisquare';
Srhofuncdef=rhofuncdef;

if coder.target('MATLAB')

    % store default values in the structure options
    options=struct('refsteps',refstepsdef,'reftol',reftoldef,...
        'eff',effdef,'effshape',effshapedef,'conflev',0.975,...
        'rhofunc',rhofuncdef,'rhofuncparam','',...
        'Srhofunc',Srhofuncdef,'Srhofuncparam','',...
        'plots',0,'nocheck',false,'yxsave',0,'intercept',true);

    % check user options and update structure options
    [varargin{:}] = convertStringsToChars(varargin{:});
    UserOptions=varargin(1:2:length(varargin));
    if ~isempty(UserOptions)
        % Check if number of supplied options is valid
        if length(varargin) ~= 2*length(UserOptions)
            error('FSDA:MMregcore:WrongInputOpt','Number of supplied options is invalid. Probably values for some parameters are missing.');
        end
        % Check if user options are valid options
        aux.chkoptions(options,UserOptions)
    end
else
    % MATLAB c coder initialization
    c=zeros(n,1);  %#ok<PREALL>
end

% Write in structure 'options' the options chosen by the user
if nargin > 2
    for i=1:2:length(varargin)
        options.(varargin{i})=varargin{i+1};
    end
end

eff     = options.eff;      % nominal efficiency
effshape= options.effshape; % nominal efficiency refers to shape or location
refsteps= options.refsteps; % maximum refining iterations
reftol  = options.reftol;   % tolerance for refining iterations convergence
rhofunc = options.rhofunc;  % String which specifies the function to use to weight the residuals

psifunc=struct;

if strcmp(rhofunc,'bisquare')

    % Compute tuning constant associated to the requested nominal efficiency
    % c = consistency factor for a given value of efficiency
    if effshape==1
        c=TBeff(eff,1,1);
    else
        c=TBeff(eff,1);
    end
    %TODO:MMregcore:shapeff

    psifunc.c=c;
    psifunc.class='TB';

    rhofuncparam=[];

elseif strcmp(rhofunc,'optimal')


    % Compute tuning constant associated to the requested nominal efficiency
    % c2 = consistency factor for a given value of efficiency
    c=OPTeff(eff,1);

    psifunc.c=c;
    psifunc.class='OPT';

    rhofuncparam=[];

elseif strcmp(rhofunc,'hyperbolic')

    if isempty(options.rhofuncparam)
        kdef=4.5;
    else
        kdef=options.rhofuncparam;
        kdef=kdef(1); % Instruction necessary for Ccoder
    end
    rhofuncparam=kdef;

    % Use (if possible) precalculated values of c,A,b,d and kc
    EFF=0.5:0.01:0.99;
    KDEF=[4 4.5 5];
    [diffeff,inddiffeff]=min(abs(eff-EFF));
    [diffk,inddiffk]=min(abs(kdef-KDEF));
    if diffeff<1e-6 && diffk<1e-06
        % Load precalculated values of tuning constants
        Mat=coder.load('private/Hyp_BdpEff.mat','MatEFF');
        row=Mat.MatEFF(inddiffeff,2:end,inddiffk);
        c2=row(1); A2=row(3); B2=row(4); d2=row(5);

        %     if kdef == 4 && eff==0.85
        %         c2 =3.212800979614258;
        %         A2 =0.570183575755717;
        %         B2 =0.696172437281084;
        %         d2 =1.205900263786317;
        %     elseif kdef == 4.5 && eff==0.85
        %         c2 =3.032387733459473;
        %         A2 =0.615717108822885;
        %         B2 = 0.723435958485131;
        %         d2 =1.321987605094910;
        %     elseif kdef == 5 && eff==0.85
        %         c2 =2.911890029907227;
        %         A2 =0.650228046997054;
        %         B2 =0.743433840145084;
        %         d2 =1.419320821762087;
        %
        %     elseif kdef == 4 && eff==0.90
        %         c2 =3.544333040714264;
        %         A2 =0.655651252372878;
        %         B2 =0.768170638356071;
        %         d2 =1.330560147762300;
        %     elseif kdef == 4.5 && eff==0.90
        %         c2 =3.313891947269440;
        %         A2 =0.697965573395585;
        %         B2 =0.792571144662011;
        %         d2 =1.452220833301545;
        %     elseif kdef == 5 && eff==0.90
        %         c2 =3.167660615756176;
        %         A2 =0.729727894789617;
        %         B2 =0.810404284656104;
        %         d2 =1.5553258180618305;
        %
        %     elseif kdef == 4 && eff==0.95
        %         c2 =4.331634521484375;
        %         A2 =0.754327484845243;
        %         B2 =0.846528826589308;
        %         d2 =1.480099129676819;
        %     elseif kdef == 4.5 && eff==0.95
        %         c2 =3.866390228271484;
        %         A2 =0.791281464739131;
        %         B2 =0.867016329355630;
        %         d2 =1.610621500015260;
        %     elseif kdef == 5 && eff==0.95
        %         c2 =3.629499435424805;
        %         A2 =0.818876452066880;
        %         B2 =0.882004888111327;
        %         d2 =1.723768949508668;

    else

        if coder.target('MATLAB')
            % Compute tuning constant associated to the requested nominal efficiency
            % c2 = consistency factor for a given value of efficiency
            [c2,A2,B2,d2]=HYPeff(eff,1,kdef);
        else
            error('FSDA:MMregcore:WrongBdpEff','Values of eff for hyperbolic tangent estimator not supported for code generation')
        end
    end


    psifunc.c=[c2;kdef;A2;B2;d2];
    psifunc.class='HYP';

    c=psifunc.c;

elseif strcmp(rhofunc,'hampel')

    if isempty(options.rhofuncparam)
        abc=[2;4;8];
    else
        abc=options.rhofuncparam;
    end
    rhofuncparam=abc;


    % Compute tuning constant associated to the requested nominal efficiency
    % c2 = consistency factor for a given value of efficiency
    c=HAeff(eff,1,abc);

    psifunc.c=[c;abc(:)];
    psifunc.class='HA';

    c=psifunc.c;

elseif strcmp(rhofunc,'mdpd')
    % Compute tuning constant associated to the requested nominal efficiency
    % c = consistency factor for a given value of efficiency
    c=PDeff(eff);

    psifunc.c=c;
    psifunc.class='PD';

    c=psifunc.c;

    rhofuncparam=[];

elseif strcmp(rhofunc,'AS')
    % Compute tuning constant associated to the requested nominal efficiency
    % c = consistency factor for a given value of efficiency
    c=ASeff(eff,1);

    psifunc.c=c;
    psifunc.class='AS';

    c=psifunc.c;

    rhofuncparam=[];

else
    error('FSDA:MMregcore:WrongRho','Specified rho function is not supported: possible values are ''bisquare'' , ''optimal'',  ''hyperbolic'', ''hampel'', ''mdpd'', ''AS''')

end

if coder.target('MATLAB')
    XXwei=strcat(psifunc.class,'wei');
    hwei=str2func(XXwei);
end

epsf = eps;
iter=0;crit=Inf;b1=b0;
b2=b0; w=y; % MATLAB Ccoder initialization
while (iter <= refsteps) && (crit > reftol)
    r1=(y-X*b1)/auxscale;
    tmp = find(abs(r1) <= epsf);
    n1 = size(tmp,1);
    if n1 ~= 0
        r1(tmp) = epsf;
    end

    % w is the weight vector \psi(x)/x, each observations receives a
    % weight. Units associated to outliers tend to have 0 weight.

    % OLD INSTRUCTION
    % w=TBwei(r1,c);

    if coder.target('MATLAB')
        % Compute weights for prespecified rho function
        w=feval(hwei,r1,c);
    else
        if strcmp(psifunc.class,'TB')
            w = TBwei(r1,c);

        elseif strcmp(psifunc.class,'OPT')
            w = OPTwei(r1,c);

        elseif strcmp(psifunc.class,'HA')
            w = HAwei(r1,c);

        elseif strcmp(psifunc.class,'HYP')
            w = HYPwei(r1,c);

        elseif strcmp(psifunc.class,'PD')
            w = PDwei(r1,c);

        elseif strcmp(psifunc.class,'AS')
            w = ASwei(r1,c);

        else
            error('FSDA:MMregcore:WrongRhoFunc','Wrong rho function supplied')
        end
    end
    % Every column of matrix X and vector y is multiplied by the sqrt root of the n x 1
    % weight vector w, then weighted regression is performed.
    w1=sqrt(w);
    Xw=bsxfun(@times,X,w1);
    Yw=y.*w1;
    % b2 = inv(X'W*X)*X'W*y where W=w*ones(1,k)
    b2=Xw\Yw;
    % disp([b2-b22])

    d=b2-b1;
    crit=max(abs(d));
    iter=iter+1;
    b1=b2;
end

out.class = 'MMreg';
out.beta = b2;
out.weights = w;
residuals=(y-X*b2)/auxscale;
out.residuals =residuals ;

% Store in output structure the outliers found with confidence level conflev
% which has been used to declared the outliers.
conflev = options.conflev;

seq = 1:n;
out.outliers = seq(abs(residuals) > sqrt(chi2inv(conflev,1)) );
out.conflev = conflev;

out.rhofunc=rhofunc;
% In case of Hampel or hyperbolic tangent estimator, store the additional
% parameters which have been used.
% For Hampel, store a vector of length 3 containing parameters a, b and c.
% For hyperbolic, store the value of k= sup CVC.
out.rhofuncparam=rhofuncparam;



% Store X (without the column of ones if there is an intercept)
if options.yxsave
    intcolumn = find(max(X,[],1)-min(X,[],1) == 0);
    if intcolumn==1
        X(:,intcolumn)=[];
        % Store X (without the column of ones if there is an intercept)
        out.X=X;
    else
        out.X=X;
    end
    % Store response
    out.y=y;
end


% Plot of residual with outliers highlighted
if options.plots==1
    laby='Robust MM residuals';
    resindexplot(out.residuals,'conflev',out.conflev,'laby',laby,'numlab',out.outliers);
end

end
%FScategory:REG-Regression




