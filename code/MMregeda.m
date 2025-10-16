function [out , varargout] = MMregeda(y,X,varargin)
%MMregeda computes MM estimator in linear regression for a series of values of efficiency
%
%
%<a href="matlab: docsearchFS('MMregeda')">Link to the help function</a>
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
%
%  Optional input arguments:
%
%
%     conflev :  Confidence level which is
%               used to declare units as outliers. Scalar.
%               Usually conflev=0.95, 0.975 0.99 (individual alpha)
%               or 1-0.05/n, 1-0.025/n, 1-0.01/n (simultaneous alpha).
%               Default value is 0.975
%                 Example - 'conflev',0.99
%                 Data Types - double
%
%
%    covrob  : scalar. A number in the set 0, 1, ..., 5 which specifies
%               the type of covariance matrix of robust beta coefficients.
%               These numbers correspond to estimators covrob, covrob1,
%               covrob2, covrob4, covrob4 and covrobc detailed inside file
%               RobCov.m. The default value is 5  (i.e. estimator covrobc).
%                 Example - 'covrob',3
%                 Data Types - single | double
%
%      eff     : nominal efficiency. Scalar or vector.
%                Vector defining nominal efficiency (i.e. a series of numbers between
%                 0.5 and 0.99). The default value is the sequence 0.5:0.01:0.99
%                 Asymptotic nominal efficiency is:
%                 $(\int \psi' d\Phi)^2 / (\psi^2 d\Phi)$
%                 Example - 'eff',[0.85 0.90 0.95 0.99]
%                 Data Types - double
%
%     effshape : location or scale efficiency. dummy scalar.
%                If effshape=1, efficiency refers to shape
%                efficiency, else (default) efficiency refers to location.
%                 Example - 'effshape',1
%                 Data Types - double
%
%  InitialEst : starting values of the MM-estimator. [] (default) or structure.
%               InitialEst must contain the following fields:
%               InitialEst.beta =  v x 1 vector (estimate of the initial regression coefficients)
%               InitialEst.scale = scalar (estimate of the scale parameter).
%               If InitialEst is empty (default) or InitialEst.beta
%               contains NaN values, program uses S estimators. In this
%               last case, it is possible to specify the options given in
%               function Sreg.
%               Example - 'InitialEst',[]
%               Data Types - struct or empty value
%
%    intercept :  Indicator for constant term. true (default) | false.
%                 Indicator for the constant term (intercept) in the fit,
%                 specified as the comma-separated pair consisting of
%                 'Intercept' and either true to include or false to remove
%                 the constant term from the model.
%                 Example - 'intercept',false
%                 Data Types - boolean
%
%        msg  : Level of output to display. Boolean. It controls whether
%                 to display or not messages on the screen.
%               If msg==true (default), messages are displayed
%               on the screen about estimated time to compute the initial S estimator
%               and the warnings about
%               'MATLAB:rankDeficientMatrix', 'MATLAB:singularMatrix' and
%               'MATLAB:nearlySingularMatrix' are set to off.
%               If msg is false, no message is displayed on the screen.
%                 Example - 'msg',false
%                 Data Types - logical
%
%       nocheck : Check input arguments. Boolean. If nocheck is equal to
%               true, no check is performed on matrix y and matrix X. Notice
%               that y and X are left unchanged. In other words, the
%               additional column of ones for the intercept is not added.
%               As default nocheck=false.
%               Example - 'nocheck',true
%               Data Types - boolean
%
%     refsteps  : Maximum iterations. Scalar.
%                 Scalar defining maximum number of iterations in the MM
%                 loop. Default value is 100.
%                 Example - 'refsteps',10
%                 Data Types - double
%
%     rhofunc : rho function. String. String which specifies the rho
%               function which must be used to weight the residuals in MM step.
%               Possible values are:
%               'bisquare';
%               'optimal';
%               'hyperbolic';
%               'hampel';
%               'mdpd';
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
%
% rhofuncparam: Additional parameters for the specified rho function in the MM step.
%               Scalar or vector.
%               For hyperbolic rho function it is possible to set up the
%               value of k = sup CVC (the default value of k is 4.5).
%               For Hampel rho function it is possible to define parameters
%               a, b and c (the default values are a=2, b=4, c=8).
%                 Example - 'rhofuncparam',5
%                 Data Types - single | double
%  Soptions  :  options if initial estimator is S and InitialEst is empty.
%               Sbestr, Sminsctol, Srhofunc, Smsg, Snsamp, Srefsteps,
%               Sreftol, Srefstepsbestr, Sreftolbestr. See function Sreg.m
%               for more details on these options.
%               It is necessary to add to the S options the letter
%               S at the beginning. For example, if you want to use the
%               optimal rho function the supplied option is
%               'Srhofunc','optimal'. For example, if you want to use 3000
%               subsets, the supplied option is 'Snsamp',3000.
%               Note that the rho function which is used in the MMstep is
%               the same as the one used in the S step.
%               Example - 'Snsamp',1000
%               Data Types - single | double
%
%       tol    : Tolerance. Scalar.
%                 Scalar controlling tolerance in the MM loop.
%                 Default value is 1e-7.
%                 Example - 'tol',1e-10
%                 Data Types - double
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
%  Output:
%
%
%  out :     A structure containing the following fields:
%       out.auxscale    =   scalar, S estimate of the scale (or supplied
%                           external estimate of scale, if option InitialEst
%                           is not empty).
%          out.Beta     =   matrix of size length(eff)-by-(p+1)
%                           containing the S estimator of regression
%                           coefficients for each value of eff.
%                           The first column contains the value of eff.
%         out.tStat     =   matrix of size length(eff)-by-(p+1)
%                           containing the MM estimator of t statistics for each
%                           value of eff. The first column contains the value
%                           of eff.
%              out.RES  =   n x length(eff) matrix containing scaled MM
%                           residuals for each value of eff.
%                           out.RES(:,jj)=(y-X*out.Beta(:,jj))/out.auxscale
%       out.Weights     =   n x length(eff) matrix. Weights assigned to
%                           each observation for each value of eff.
%       out.Outliers    =   n x length(eff) Boolean matrix containing the
%                           outliers which have been found for each value
%                           of eff.
%       out.Sbeta       =   p x 1 vector containing S estimate of regression
%                           coefficients (or supplied initial external
%                           estimate of regression coefficients, if option
%                           InitialEst is not empty).
%       out.Ssingsub    =   Number of subsets without full rank in the S
%                           preliminary part. Notice that
%                           out.singsub > 0.1*(number of subsamples)
%                           produces a warning.
%       out.conflev     =   Confidence level that was used to declare outliers.
%           out.rhofunc =   string identifying the rho function which has been
%                           used.
%      out.rhofuncparam =   vector which contains the additional parameters
%                           for the specified rho function that have been
%                           used. For hyperbolic rho function the value of
%                           k =sup CVC. For Hampel rho function the parameters
%                           a, b and c.
%        out.Outliers = Boolean matrix containing the list of
%                       the units declared as outliers for each value of eff using confidence
%                       level specified in input scalar conflev.
%            out.eff    =   vector containing the value of eff which have
%                           been used.
%           out.Sbeta   = vector. S initial estimate of regression
%                         coefficients.
%            out.y      =  response vector y.
%            out.X=    Data matrix of explanatory variables
%                     which has been used (it also contains the column of ones if
%                     input option intercept was missing or equal to 1).
%       out.class       =   'MMregeda'.
%
%  Optional Output:
%
%            C        : matrix containing the indices of the subsamples
%                       extracted for computing the estimate (the so called
%                       elemental sets).
%
%
% See also: Sreg
%
% References:
%
% Riani, M., Cerioli, A., Atkinson, A.C. and Perrotta, D. (2014), Monitoring
% Robust Regression, "Electronic Journal of Statistics", Vol. 8, pp. 646-677.
%
% Maronna, R.A., Martin D. and Yohai V.J. (2006), "Robust Statistics, Theory
% and Methods", Wiley, New York.
%
% Acknowledgements:
%
%
% Copyright 2008-2025.
% Written by FSDA team
%
%
%<a href="matlab: docsearchFS('MMregeda')">Link to the help page for this function</a>
%
%$LastChangedDate::                      $: Date of the last commit

% Examples:

%{
    % MMregeda with all default options.
    n=200;
    p=3;
    randn('state', 123456);
    X=randn(n,p);
    % Uncontaminated data
    y=randn(n,1);
    % Contaminated data
    ycont=y;
    ycont(1:5)=ycont(1:5)+6;
    [out]=MMregeda(ycont,X);
%}

%{
    % MMregeda with optional input arguments.
    % MMregeda using the optimal rho function
    n=200;
    p=3;
    randn('state', 123456);
    X=randn(n,p);
    % Uncontaminated data
    y=randn(n,1);
    % Contaminated data
    ycont=y;
    ycont(1:5)=ycont(1:5)+6;
    [out]=MMregeda(ycont,X,'Srhofunc','optimal','rhofunc','optimal');
%}

%{
    %% Comparing the output of different MMreg runs.
    state=100;
    randn('state', state);
    n=100;
    X=randn(n,3);
    bet=[3;4;5];
    y=3*randn(n,1)+X*bet;
    y(1:20)=y(1:20)+13;

    %For outlier detection we consider both the nominal individual 1%
    %significance level and the simultaneous Bonferroni confidence level.

    % Define nominal confidence level
    conflev=[0.99,1-0.01/length(y)];
    % Define number of subsets
    nsamp=3000;

    % MM estimators
    [out]=MMregeda(y,X,'conflev',conflev(1));
    laby='Scaled MM residuals';
    resfwdplot(out)
%}

%% Beginning of code

% Input parameters checking
nnargin=nargin;
vvarargin=varargin;
[y,X,n,p] = aux.chkinputR(y,X,nnargin,vvarargin);

% default values for the initial S estimate:

% default value of break down point
Sbdpdef=0.5;
% default values for msg
Smsgdef=true;
% default values of subsamples to extract
Snsampdef=20;
% default value of number of refining iterations (C steps) for each extracted subset
Srefstepsdef=3;
% default value of tolerance for the refining steps convergence for each extracted subset
Sreftoldef=1e-6;
% default value of number of best locs to remember
Sbestrdef=5;
% default value of number of refining iterations (C steps) for best subsets
Srefstepsbestrdef=50;
% default value of tolerance for the refining steps convergence for best subsets
Sreftolbestrdef=1e-8;
% default value of tolerance for finding the minimum value of the scale
% both for each extracted subset and each of the best subsets
Sminsctoldef=1e-7;

% rho (psi) function which has to be used to weight the residuals in the S
% step.
Srhofuncdef='bisquare';
Srhofuncparamdef=[];
% rho (psi) function which has to be used to weight the residuals in the MM
% step.
rhofuncdef='bisquare';
rhofuncparamdef=[];
covrobdef=5;



% default values of nominal efficiency that are used.
eff=0.5:0.01:0.99;

if coder.target('MATLAB')

    options=struct('intercept',true,'InitialEst','','Smsg',Smsgdef,'Snsamp',Snsampdef,'Srefsteps',Srefstepsdef,...
        'Sbestr',Sbestrdef,'Sreftol',Sreftoldef,'Sminsctol',Sminsctoldef,...
        'Srefstepsbestr',Srefstepsbestrdef,'Sreftolbestr',Sreftolbestrdef,...
        'Sbdp',Sbdpdef,'Srhofunc',Srhofuncdef,'Srhofuncparam',Srhofuncparamdef,'nocheck',false,'eff',eff,'effshape',0,...
        'refsteps',100,'tol',1e-7,'conflev',0.975,'plots',0,'rhofunc',rhofuncdef, ...
        'rhofuncparam',rhofuncparamdef,'covrob',covrobdef);

    [varargin{:}] = convertStringsToChars(varargin{:});
    UserOptions=varargin(1:2:length(varargin));
    if ~isempty(UserOptions)

        % Check if number of supplied options is valid
        if length(varargin) ~= 2*length(UserOptions)
            error('FSDA:MMreg:WrongInputOpt','Number of supplied options is invalid. Probably values for some parameters are missing.');
        end

        % Check if all the specified optional arguments were present
        % in structure options
        inpchk=isfield(options,UserOptions);
        WrongOptions=UserOptions(inpchk==0);
        if ~isempty(WrongOptions)
            disp(strcat('Non existent user option found->', char(WrongOptions{:})))
            error('FSDA:MMregeda:NonExistInputOpt','In total %d non-existent user options found.', length(WrongOptions));
        end
    end
end

if nargin > 2
    % Write in structure 'options' the options chosen by the user
    for i=1:2:length(varargin)
        options.(varargin{i})=varargin{i+1};
    end
end


% intercept=options.intercept;

% InitialEst = structure which contains initial estimate of beta and sigma.
% If InitialEst is empty, then initial estimates of beta and sigma come from
% S-estimation.
InitialEst=options.InitialEst;

% rho function to use in the MM step.
rhofunc = options.rhofunc;
rhofuncparam=options.rhofuncparam;
covrob=options.covrob;


if isempty(InitialEst) || (isstruct(InitialEst) && any(isnan(InitialEst.beta)))

    bdp = options.Sbdp;              % break down point
    refsteps = options.Srefsteps;    % refining steps
    bestr = options.Sbestr;          % best locs for refining steps till convergence
    nsamp = options.Snsamp                                                                                                                                                                          ;          % subsamples to extract
    reftol = options.Sreftol;        % tolerance for refining steps
    minsctol = options.Sminsctol;    % tolerance for finding minimum value of the scale for each subset
    refstepsbestr=options.Srefstepsbestr;  % refining steps for the best subsets
    reftolbestr=options.Sreftolbestr;      % tolerance for refining steps for the best subsets

    Srhofunc=options.Srhofunc;           % rho function which must be used
    Srhofuncparam=options.Srhofuncparam;    % eventual additional parameters associated to the rho function
    msg=options.Smsg;                  % message on the screen about computational time of S estimator

    % first compute S-estimator with a fixed breakdown point

    % SR is the routine which computes S estimates of beta and sigma in regression
    % Note that intercept is taken care of by chkinputR call.
    if nargout==2
        [Sresult , C] = Sreg(y,X,'nsamp',nsamp,'bdp',bdp,'refsteps',refsteps,'bestr',bestr,...
            'reftol',reftol,'minsctol',minsctol,'refstepsbestr',refstepsbestr,...
            'reftolbestr',reftolbestr,'rhofunc',Srhofunc,'rhofuncparam',Srhofuncparam,...
            'nocheck',true,'msg',msg,'conflev',0.95,'yxsave',false);

    else
        Sresult = Sreg(y,X,'nsamp',nsamp,'bdp',bdp,'refsteps',refsteps,'bestr',bestr,...
            'reftol',reftol,'minsctol',minsctol,'refstepsbestr',refstepsbestr,...
            'reftolbestr',reftolbestr,'rhofunc',Srhofunc,'rhofuncparam',Srhofuncparam,...
            'nocheck',true,'msg',msg,'conflev',0.95,'yxsave',false);
        C=0;
    end


    bs = Sresult.beta;
    ss = Sresult.scale;
    singsub=Sresult.singsub;
else
    C=0;
    bs = InitialEst.beta;
    ss = InitialEst.scale;
    singsub=0;
end
varargout = {C};

% Asymptotic nominal efficiency (for location or shape)
eff = options.eff;

% effshape = scalar which specifies whether nominal efficiency refers to location or scale
effshape = options.effshape;

% refsteps = maximum number of iteration in the MM step
refsteps = options.refsteps;

% tol = tolerance to declare convergence in the MM step
tol = options.tol;

% MMregcore = function which does IRWLS steps from initialbeta (bs) and sigma (ss)
% Notice that the estimate of sigma (scale) remains fixed
plots=options.plots;
conflev=options.conflev;

% Initialize quantities to store for each value of eff
leff=length(eff);

% Beta= matrix which will contain beta coefficients
Beta=[eff(:) zeros(leff,p)];
% tStat = matrix which will contain t statistics
tStat=Beta;

Weights=zeros(n,leff);
Residuals=zeros(n,leff);
Outliers=false(n,leff);

out = struct;

for jj=1:length(eff)
    outIRW = MMregcore(y,X,bs,ss,'eff',eff(jj),'effshape',effshape,...
        'refsteps',refsteps,'reftol',tol,'conflev',conflev,'plots',0,'nocheck',true,...
        'rhofunc',rhofunc,'rhofuncparam',rhofuncparam,'yxsave',false);

    residuals=(y-X*outIRW.beta)/ss;

    [outCOV]=RobCov(X,residuals,ss,'rhofunc',rhofunc,'rhofuncparam',rhofuncparam, ...
        'eff',eff(jj),'intercept',0);


    if covrob==0
        covrobMM=outCOV.covrob;
    elseif covrob==5
        covrobMM=outCOV.covrobc;
    else
        if any(covrob==1:4)
            covrobMM=outCOV.("covrob" + covrob);
        else
            error('FSDA:Sregeda:Wrongcovrob','Option covrob must be a number in the set 0, 1, ...5')
        end
    end
    tstatMM=outIRW.beta./(sqrt(diag(covrobMM)));

    Residuals(:,jj)=residuals;
    Beta(jj,2:end)=outIRW.beta;
    tStat(jj,2:end)=tstatMM';

    Weights(:,jj)=outIRW.weights;
    Outliers(outIRW.outliers,jj)=true;
end

% Store quantities which depend on the value of eff(jj)
out.Beta = Beta;
out.tStat= tStat;
out.RES =  Residuals; % MM scaled residuals
out.Weights=Weights;
out.Outliers=Outliers;

% Store quantities which do not depend on the value of eff(jj)
out.Sbeta = bs;
out.auxscale = ss;
out.Ssingsub=singsub;
out.conflev=conflev;
out.class='MMregeda';

out.rhofunc=rhofunc;
% In case of Hampel or hyperbolic tangent estimator, store the additional
% parameters which have been used.
% For Hampel, store a vector of length 3 containing parameters a, b and c.
% For hyperbolic, store the value of k= sup CVC.
out.rhofuncparam=rhofuncparam;

% Store values of efficiency
out.eff=eff;

out.X=X;
% Store response
out.y=y;


% Plot monitoring of scaled MM residuals for each value of eff
if plots==1
    resfwdplot(out)
end
end
%FScategory:REG-Regression