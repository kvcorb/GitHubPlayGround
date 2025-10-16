function [reduced_est, reduced_model, msgstr] = LTStsVarSel(y,varargin)
%LTStsVarSel does variable selection in the robust time series model LTSts
%
%<a href="matlab: docsearchFS('LTStsVarSel')">Link to the help function</a>
%
% LTSts requires variable selection when the optimal model parameters are
% not known in advance. This happens in particular when the function has to
% be applied to many heterogeneous datasets in an automatic way, possibly
% on a regular basis (that is the model parameters are expected to change
% over time even for datasets associated to the same phenomenon).
%
% The approach consists in iteratively eliminating the less significant
% estimated model parameter, starting from an over-parametrized model. The
% model parameters are re-estimated with LTSts at each step, until all the
% p-values are below a given threshold. Then, the output is a reduced time
% series model with significant parameters only.
%
%
%  Required input arguments:
%
%    y:         Time series to analyze. Vector. A row or a column vector
%               with T elements, which contains the time series.
%
%
%  Optional input arguments:
%
% firstTestLS: initial test for presence of level shift. Boolean. If
%               firstTestLS is true, we immediately find the position of
%               the level shift in a model which does not contain
%               autoregressive terms, the seasonal specification is 101. If
%               the level shift component is significant we pass the level
%               shift component in fixed position to the variable selection
%               procedure. Note also that the units declared as outliers
%               with a p-value smaller than 0.001 are used to form
%               model.ARtentout. model.ARtentout is used in the subsequent
%               steps of the variable selection procedure, every time there
%               is a call to LTSts with an autoregressive component. The
%               default value of firstTestLS is false.
%                 Example - 'firstTestLS', false
%                 Data Types - logical
%
%    model:     model type. Structure. A structure which specifies the
%               (over-parametrized) model which will be used to initialise
%               the variable selection process. The model structure is
%               identical to the one defined for function LTSts: for
%               convenience, we list the fields also here:
%
%               model.s = scalar (length of seasonal period). For monthly
%                         data s=12 (default), for quarterly data s=4, ...
%               model.trend = scalar (order of the trend component).
%                       trend = 0 implies no trend,
%                       trend = 1 implies linear trend with intercept,
%                       trend = 2 implies quadratic trend,
%                       trend = 3 implies cubic trend.
%                       Admissible values for trend are, 0, 1, 2 and 3.
%                       In the paper RPRH to denote the order of the trend,
%                       symbol A is used. If this field is not present into
%                       input structure model, model.trend=2 is used.
%               model.seasonal = scalar (integer specifying number of
%                        frequencies), i.e. harmonics, in the seasonal
%                        component. Possible values for seasonal are
%                        $1, 2, ..., [s/2]$, where $[s/2]=floor(s/2)$.
%                        For example:
%                        if seasonal =1 we have:
%                        $\beta_1 \cos( 2 \pi t/s) + \beta_2 sin ( 2 \pi t/s)$;
%                        if seasonal =2 we have:
%                        $\beta_1 \cos( 2 \pi t/s) + \beta_2 \sin ( 2 \pi t/s)
%                        + \beta_3 \cos(4 \pi t/s) + \beta_4 \sin (4 \pi t/s)$.
%                        Note that when $s$ is even, the sine term disappears
%                        for $j=s/2$ and so the maximum number of
%                        trigonometric parameters is $s-1$.
%                        If seasonal is a number greater than 100, then it
%                        is possible to specify how the seasonal component
%                        grows over time.
%                        For example, seasonal = 101 implies a seasonal
%                        component which just uses one frequency
%                        which grows linearly over time as follows:
%                        $(1+\beta_3 t)\times ( \beta_1 cos( 2 \pi t/s) +
%                        \beta_2 \sin ( 2 \pi t/s))$.
%                        For example, seasonal =201 implies a seasonal
%                        component which just uses one frequency
%                        which grows in a quadratic way over time as
%                        follows:
%                        $(1+\beta_3 t + \beta_4  t^2)\times( \beta_1 \cos(
%                        2 \pi t/s) + \beta_2 \sin ( 2 \pi t/s))$.
%                        seasonal =0 implies a non seasonal model.
%                       In the paper RPRH, to denote the number of
%                       frequencies of the seasonal component,
%                       symbol B is used, while symbol G is used to denote
%                       the order of the trend of the seasonal component.
%                       Therefore, for example, model.seasonal=201
%                       corresponds to B=1 and G=2, while model.seasonal=3
%                       corresponds to B=3 and G=0.
%                       If this field is not present into
%                       input structure model, model.seasonal=303 is used.
%               model.X  =  matrix of size T-by-nexpl containing the
%                         values of nexpl extra covariates which are likely
%                         to affect y.
%               model.lshift = scalar or vector associated to level shift
%                       component. lshift=0 (default) implies no level
%                       shift component.
%                       If model.lshift is vector of positive integers,
%                         then it is associated to the positions of level
%                         shifts which have to be considered. The most
%                         significant one is included in the fitted model.
%                         For example, if model.lshift =[13 20 36], a
%                         tentative level shift is imposed in position
%                         $t=13$, $t=20$ and $t=36$. The most significant
%                         among these positions is included in the final
%                         model. In other words, the following extra
%                         parameters are added to the final model:
%                         $\beta_{LS1}* I(t \geq \beta_{LS2})$ where
%                         $\beta_{LS1}$ is a real number (associated with
%                         the magnitude of the level shift) and
%                         $\beta_{LS2}$ is an integer which assumes values
%                         13, 20 or 36 and and $I$ denotes the indicator
%                         function.
%                         As a particular case, if model.lshift =13 then a
%                         level shift in position $t=13$ is added to the
%                         model. In other words the following additional
%                         parameters are added: $\beta_{LS1}* I(t \geq 13)$
%                         where $\beta_{LS1}$ is a real number and $I$
%                         denotes the indicator function.
%                       If lshift = -1 tentative level shifts are
%                         considered for positions $p+1,p+2, ..., T-p$ and
%                         the most significant one is included in the final
%                         model ($p$ is the total number of parameters in
%                         the fitted model). Note that lshift=-1 is not
%                         supported for C-coder translation.
%                       In the paper RPRH $\beta_{LS1}$ is denoted with
%                       symbol $\delta_1$, while, $\beta_{LS2}$ is denoted
%                       with symbol $\delta_2$.
%               model.ARp = vector with non negative integer numbers
%                       specifying the autoregressive
%                       components. For example:
%                        model.ARp=[1 2] means a AR(2) process;
%                        model.ARp=2 means just the lag 2 component;
%                        model.ARp=[1 2 5 8] means AR(2) + lag 5 + lag 8;
%                        model.ARp=0 (default) means no autoregressive component.
%               model.ARtentout = matrix of size r-by-2 containing the list
%                       of the units declared as outliers (first column)
%                       and corresponding fitted values (second column) or
%                       empty scalar. If model.ARtentout is not empty, when
%                       the autoregressive component is present, the y
%                       values which are used to compute the autoregressive
%                       component are replaced by model.tentout(:,2) for
%                       the units contained in model.tentout(:,1)
%                 Example - 'model', model
%                 Data Types - struct
%               Remark: the default overparametrized model is for monthly
%               data with a quadratic
%               trend (3 parameters) + seasonal component with three
%               harmonics which grows in a cubic way over time (9 parameters),
%               no additional explanatory variables, no level shift
%               and no AR component that is:
%                               model=struct;
%                               model.s=12;
%                               model.trend=2;
%                               model.seasonal=303;
%                               model.X='';
%                               model.lshift=0;
%                               model.ARp=0;
%               Using the notation of the paper RPRH we have A=2, B=3; G=3; and
%               $\delta_1=0$.
%
%       nsamp : number of subsamples to extract. Scalar or vector of length 2.
%               Vector of length 1 or 2 which controls the number of
%               subsamples which will be extracted to find the robust
%               estimator. If lshift is not equal to 0 then nsamp(1)
%               controls the number of subsets which have to be extracted
%               to find the solution for t=lshift(1). nsamp(2) controls the
%               number of subsets which have to be extracted to find the
%               solution for t=lshift(2), lshift(3), ..., lshift(end).
%               Note that nsamp(2) is generally smaller than nsamp(1)
%               because in order to compute the best solution for
%               t=lshift(2), lshift(3), ..., lshift(end), we use the lts.bestr/2
%               best solutions from previous t (after shifting the
%               position of the level shift in the estimator of beta). If
%               lshift is a vector of positive integers the default value
%               of nsamp is (500 250). If
%               lshift is a vector of positive integers and nsamp is supplied as a scalar the default
%               is to extract [nsamp/2] subsamples for t=lshift(1),
%               lshift(2), ... Therefore, for example, in order to extract
%               600 subsamples for t=lshift(1) and 300 subsamples for t=
%               lshift(2) ... you can use nsamp =600 or nsamp=[600 300].
%               The default value of nsamp is 1000;
%                 Example - 'nsamp',500
%                 Data Types - double
%               Remark: if nsamp=0 ,all subsets will be extracted.
%               They will be (n choose p).
%
%    thPval:    threshold for pvalues. Scalar. A value between 0 and 1.
%               An estimated parameter/variable is eliminated if the
%               associated pvalue is below thPval. Default is thPval=0.01.
%                 Example - 'thPval',0.05
%                 Data Types - double
%
%    plots:     Plots on the screen. Scalar.
%               If plots = 1, the typical LTSts plots will be shown on the
%               screen. The default value of plot is 0 i.e. no plot is
%               shown on the screen.
%                 Example - 'plots',1
%                 Data Types - double
%
%    msg:       Messages on the screen. Scalar.
%               Scalar which controls whether LTSts will display or not
%               messages on the screen. Default is msg=0, that is no
%               messages are displayed on the screen. If msg==1, messages
%               displayed on the screen are about estimated time to compute
%               the estimator and the warnings about
%               'MATLAB:rankDeficientMatrix', 'MATLAB:singularMatrix' and
%               'MATLAB:nearlySingularMatrix'.
%               Example - 'msg',1
%               Data Types - double
%
%  dispresults : Display results of final fit. Boolean. If dispresults is
%               true, labels of coefficients, estimated coefficients,
%               standard errors, tstat and p-values are shown on the
%               screen in a fully formatted way. The default value of
%               dispresults is false.
%               Example - 'dispresults',true
%               Data Types - logical
%
%
%  Output:
%
%  reduced_est:  A reduced model structure obtained by eliminating
%                    parameters that are non-significant. It is a structure
%                    containing the typical input model fields for function
%                    LTSts (refer to LTSts for details):
%                    model.s = the optimal length of seasonal period.
%                    model.trend = the optimal order of the trend.
%                    model.seasonal = the optimal number of frequencies in
%                      the seasonal component.
%                    model.lshift = the optimal level shift position.
%                    model.X = a matrix containing the values of the extra
%                      covariates which are likely to affect y. If the
%                      input model specifies autoregressive components
%                      in model.ARp, then the selected ones will be also
%                      included in model.X.
%
% reduced_model:  Structure containing the output fields of the optimal model.
%                    The fields are those of function LTSts (refer to
%                    LTSts for details):
%                    out.B = matrix of estimated beta coefficients.
%                    out.h = number of observations that have determined
%                      the initial LTS estimator.
%                    out.bs = vector of the units with the smallest
%                      squared residuals before the reweighting step.
%                    out.Hsubset = matrix of the units forming best H
%                      subset for each tentative level shift considered.
%                    out.numscale2 = matrix of the values of the lts.bestr
%                      smallest values of the target function.
%                    out.BestIndexes = matrix of indexes associated with
%                      the best nbestindexes solutions.
%                    out.Likloc = matrix containing local sum of squares
%                      of residuals determining the best position of level
%                      shift.
%                    out.RES = matrix containing scaled residuals for all
%                      the units of the original time series monitored in
%                      steps lshift+1, lshift+2, ....
%                    out.yhat = vector of fitted values after final step.
%                    out.residuals = vector of scaled residuals from
%                      after final NLS step.
%                    out.weights = vector of weights after adaptive
%                      reweighting.
%                    out.scale = final scale estimate of the residuals
%                      using final weights.
%                    out.conflev = confidence level used to declare outliers.
%                    out.outliers = vector of the units declared outliers.
%                    out.singsub = number of subsets without full rank.
%                    out.y = response vector y.
%                    out.X = data matrix X containing trend, seasonal, expl
%                       (with autoregressive component) and lshift.
%                    out.class = 'LTSts'.
%
%
%  Optional Output:
%
%         msgstr     : String containing the last warning message.
%                      This relates to the execution of the LTS.
%
% See also LTSts
%
% References:
%
% Rousseeuw, P.J., Perrotta D., Riani M. and Hubert, M. (2018), Robust
% Monitoring of Many Time Series with Application to Fraud Detection,
% "Econometrics and Statistics". [RPRH]
%
%
% Copyright 2008-2025.
% Written by FSDA team
%
%
%<a href="matlab: docsearchFS('LTStsVarSel')">Link to the help function</a>
%
%$LastChangedDate:: 2019-08-31 00:40:12 #$: Date of the last commit
%
% Examples:
%
%
%{
    % run LTStsVarSel with all default options.
    
    rng('default')
    rng(1);
    
    % data model
    model=struct;
    model.trend=1;                  % linear trend
    model.trendb=[0 1];             % parameters of the linear trend
    model.s=12;                     % monthly time series
    model.seasonal=1;               % 1 harmonic
    model.seasonalb=[10 10];        % parameter for one harmonic
    model.signal2noiseratio = 100;  % signal to noise ratio
    
    n = 100;                        % sample size
    % generate data
    out_sim=simulateTS(n,'plots',1,'model',model);

    %run LTStsVarSel with all default options
    [out_model_0, out_reduced_0] = LTStsVarSel(out_sim.y);
 
    % optional: add a FS step to the LTSts estimator
    % outFS = FSRts(out_sim.y,'model',out_model_0);
    % To be fixed: 'Non existent user option found-> '    'ARp'
%}

%{
    % run LTStsVarSel starting from a specific over-parametrized model.
    
    rng('default')
    rng(1);
    
    % sample size
    n = 100;                       
    tmp = rand(n,1);
     
    % data model
    model=struct;
    model.trend=1;                  % linear trend
    model.trendb=[0 1];             % parameters of the linear trend
    model.s=12;                     % monthly time series
    model.seasonal=1;               % 1 harmonic
    model.seasonalb=[10 10];        % parameter for one harmonic
    model.lshiftb=100;              % level shift amplitude
    model.lshift= 30;               % level shift position
    model.signal2noiseratio = 100;  % signal to noise ratio
    model.X = tmp.*[1:n]';          % a extra covariate
    model.Xb = 1;                   % beta coefficient of the covariate
    out_sim=simulateTS(n,'plots',1,'model',model);
    
    % complete model to be tested.
    overmodel=struct;
    overmodel.trend=2;              % quadratic trend
    overmodel.s=12;                 % monthly time series
    overmodel.seasonal=303;         % number of harmonics
    overmodel.lshift=4:n-4;         % positions of level shift which have to be considered
    overmodel.X=tmp.*[1:n]';

    % pval threshold
    thPval=0.01;

    [out_model_1, out_reduced_1] = LTStsVarSel(out_sim.y,'model',overmodel,'thPval',thPval,'plots',1);

%}

%{
    % run LTStsVarSel starting from over-parametrized model with autoregressive components.
    
    rng('default')
    rng(1);
    
    % add three autoregressive components to the complete model.
    
    n = 100;                        % sample size
    tmp = rand(n,1);
    model=struct;
    model.trend=1;                  % linear trend
    model.trendb=[0 1];             % parameters of the linear trend
    model.s=12;                     % monthly time series
    model.seasonal=1;               % 1 harmonic
    model.seasonalb=[10 10];
    model.X = tmp.*[1:n]';          % a extra covariate
    model.Xb = 1;                   % beta coefficient of the covariate
    model.signal2noiseratio = 100;  % signal to noise ratio
    out_sim=simulateTS(n,'plots',1,'model',model);
    
    % complete model to be tested.
    overmodel=struct;
    overmodel.trend=2;              % quadratic trend
    overmodel.s=12;                 % monthly time series
    overmodel.seasonal=303;         % number of harmonics
    overmodel.lshift=0;             % no level shift
    overmodel.X=tmp.*[1:n]';
    overmodel.ARp=1:3;

    % pval threshold
    thPval=0.01;
     
    [out_model_2, out_reduced_2] = LTStsVarSel(out_sim.y,'model',overmodel,'thPval',thPval);
%}

%{
    % run LTStsVarSel with default options and return warning messages.
    
    rng('default')
    rng(1);
    
    % data model
    model=struct;
    model.trend=1;                  % linear trend
    model.trendb=[0 1];             % parameters of the linear trend
    model.s=12;                     % monthly time series
    model.seasonal=1;               % 1 harmonic
    model.seasonalb=[10 10];        % parameter for one harmonic
    model.lshiftb=100;              % level shift amplitude
    model.lshift= 30;               % level shift position
    model.signal2noiseratio = 100;  % signal to noise ratio
    
    n = 100;                        % sample size
    tmp = rand(n,1);
    model.X = tmp.*[1:n]';          % a extra covariate
    model.Xb = 1;                   % beta coefficient of the covariate
    % generate data
    out_sim=simulateTS(n,'plots',1,'model',model);
    [out_model_3, out_reduced_3, messages] = LTStsVarSel(out_sim.y);
%}


%{
    % An example of the use of option firstTestLS
    rng('default')
    rng(10);
    
    % data model
    model=struct;
    model.trend=1;                  % linear trend
    model.trendb=[0 1];             % parameters of the linear trend
    model.s=12;                     % monthly time series
    model.seasonal=1;               % 1 harmonic
    model.seasonalb=[2 3];          % parameter for one harmonic
    model.lshiftb=50;               % level shift amplitude
    model.lshift= 35;               % level shift position
    model.signal2noiseratio = 30;   % signal to noise ratio
    model.ARp=1;
    model.ARb=0.9;
    n = 50;                         % sample size
    tmp = rand(n,1);
    model.X = tmp;                  % a extra covariate
    model.Xb = 1;                   % beta coefficient of the covariate
    % generate data
    out_sim=simulateTS(n,'plots',1,'model',model);
    
    
    overmodel=model;
    overmodel.trend=2;              % quadratic trend
    overmodel.s=12;                 % monthly time series
    overmodel.seasonal=303;         % number of harmonics
    overmodel.lshift=-1;
    overmodel=rmfield(overmodel,"trendb");
    overmodel=rmfield(overmodel,"seasonalb");
    overmodel=rmfield(overmodel,"signal2noiseratio");
    overmodel=rmfield(overmodel,"lshiftb");
    overmodel=rmfield(overmodel,"Xb");
    overmodel=rmfield(overmodel,"ARb");
    nsamp=100;
    tic;
    [out_model_3, out_reduced_3] = LTStsVarSel(out_sim.y, ...
        'model',overmodel,'nsamp',nsamp);
    compTime=toc; 
    disp(compTime)
    disp('Final selected model without option firstTestLS')
    disp(out_model_3)
    [out_model_3N, out_reduced_3N] = LTStsVarSel(out_sim.y, ...
        'model',overmodel,'firstTestLS',true,'nsamp',nsamp);
    disp('Final selected model with option firstTestLS')
    disp(out_model_3N)
%}

%% Beginning of code

% Input parameters checking

warning('off','all');

if nargin<1
    error('FSDA:LTStsVarSel:MissingInputs','Input time series is missing');
end

% Set up defaults for the over-parametrized model
modeldef          = struct;
modeldef.trend    = 2;        % quadratic trend
modeldef.s        = 12;       % monthly time series
modeldef.seasonal = 303;      % three harmonics growing cubically (B=3, G=3)
modeldef.X        = [];       % no extra explanatory variable
modeldef.lshift   = 0;        % no level shift
modeldef.ARp      = 0;        % no autoregressive component
modeldef.ARtentout =[];

nsamp=500;
firstTestLS=false;

options=struct('model',modeldef, 'thPval', 0.01, ...
    'plots',0,'msg',0,'dispresults',0,'nsamp',nsamp,'firstTestLS',firstTestLS);

[varargin{:}] = convertStringsToChars(varargin{:});
UserOptions=varargin(1:2:length(varargin));
if ~isempty(UserOptions)
    % Check if number of supplied options is valid
    if length(varargin) ~= 2*length(UserOptions)
        error('FSDA:LTStsVarSel:WrongInputOpt','Number of supplied options is invalid. Probably values for some parameters are missing.');
    end

    % Check if all optional arguments were present in structure options
    inpchk=isfield(options,UserOptions);
    WrongOptions=UserOptions(inpchk==0);
    if ~isempty(WrongOptions)
        disp(strcat('Non existent user option found->', char(WrongOptions{:})))
        error('FSDA:LTStsVarSel:NonExistInputOpt','In total %d non-existent user options found.', length(WrongOptions));
    end

    % Write in structure 'options' the options chosen by the user
    for i=1:2:length(varargin)
        options.(varargin{i})=varargin{i+1};
    end
end

% Put User options inside modeldef
if ~isequal(options.model,modeldef)
    fld=fieldnames(options.model);
    aux.chkoptions(modeldef,fld)
    for i=1:length(fld)
        modeldef.(fld{i})=options.model.(fld{i});
    end
end
% and finally set the over-parametrized model to start with
model = modeldef;

thPval = options.thPval;
plots  = options.plots;
msg    = options.msg;
dispresults = options.dispresults;
nsamp=options.nsamp;
firstTestLS=options.firstTestLS;
posLS=0;


%% Step 1: estimate model parameters with LTSts for the over-parametrized input model

n   = size(y,1);     % number of observations in the input dataset
h1  = round(n*0.9);  % default for h (num. obs. for the LTS estimator)

% If firstTestLS is true, we immediately find the position of the level shift
% in a model which does not contains autoregressive terms and
% and seasonal specification is 101.
% If the level shift component is significant we pass the level shift
% component in fixed position to the variable selection procedure.
if firstTestLS==true && (length(model.lshift)>1 || model.lshift(1)==-1)
    modelINI=model;
    modelINI.ARp=0;
    modelINI.seasonal=101;
    % Note that all the other components do not change
    out_LTStsINI = LTSts(y,'model',modelINI,'nsamp',nsamp,'h',h1,...
        'plots',plots,'msg',msg,'dispresults',dispresults,'SmallSampleCor',1);
    if out_LTStsINI.LevelShiftPval<thPval
        posLS=out_LTStsINI.posLS;
        model.lshift=out_LTStsINI.posLS;
    else
        model.lshift=0;
    end

    % Find the observations which surely are outliers (i.e. those which
    % have a pvalue smaller than 0.001)
    tentOutForAR=out_LTStsINI.outliers(out_LTStsINI.outliersPval<0.001);
    yhatout=out_LTStsINI.yhat(tentOutForAR);
    ARtentout=[tentOutForAR yhatout];
    model.ARtentout=ARtentout;
end

% Estimate the parameters based on initial full model
out_LTSts = LTSts(y,'model',model,'nsamp',nsamp,'h',h1,...
    'plots',plots,'msg',msg,'dispresults',dispresults,'SmallSampleCor',1);



if plots
    a=gcf;
    if isfield(model,'X')
        title(a.Children(end),['trend =' num2str(model.trend) ', seas = ' num2str(model.seasonal) ' every ' num2str(model.s) ' months , X = ' num2str(size(model.X,2)) ]);
    else
        title(a.Children(end),['trend =' num2str(model.trend) ', seas = ' num2str(model.seasonal) ' every ' num2str(model.s) ' months']);
    end
end

%% Step 2: iterate and reduce the model

% Step (2a) tests the model parameters. It consists in identifying the
% largest p-value among the parameters of:
% - level shift,
% - harmonics,
% - covariates,
% - the largest degree component of:
%   * trend,
%   * amplitude of harmonics,
%   * AR component.
%
% Step (2b) re-estimates the model. It removes the least significant parameter
% and re-estimates the model with LTSts. Remark: the level shift position
% is not re-estimated, but the original estimate is kept as is.


% Initializations

% AllPvalSig = dichotomic variable that becomes 1 if all variables are
% significant. This means that the variables are to be kept and the
% iterative procedure should stop.
AllPvalSig=0;

% Iterative model reduction.
while AllPvalSig == 0
    % The loop terminates when all p-values are smaller than thPval. In
    % this case AllPvalSig will become equal to 1

    rownam=out_LTSts.Btable.Properties.RowNames;
    seqp=1:length(rownam);

    % Position of the last element of the trend component
    posLastTrend=max(seqp(contains(rownam,'b_trend')));
    if posLastTrend>1
        LastTrendPval=out_LTSts.Btable{posLastTrend,'pval'};
    else
        LastTrendPval=0;
    end

    posX=seqp(contains(rownam,'b_explX'));
    if ~isempty(posX)
        % p values of the explanatory var component
        PvalX=out_LTSts.Btable{posX,'pval'};

        [maxPvalX,posmaxPvalX]=max(PvalX);
        %posmaxPvalX=posX(posmaxPvalX);
    else
        maxPvalX=0;
        posmaxPvalX=[];
    end

    posLastVarAmpl=max(seqp(contains(rownam,'b_varam')));

    if ~isempty(posLastVarAmpl)
        LastVarAmplPval=out_LTSts.Btable{posLastVarAmpl,'pval'};
    else
        LastVarAmplPval=0;
    end

    if ~isempty(out_LTSts.LastHarmonicPval)
        LastHarmonicPval=out_LTSts.LastHarmonicPval;
    else
        LastHarmonicPval=0;
    end

    if model.lshift(1)~=0
        LevelShiftPval=out_LTSts.LevelShiftPval;
        posLS=out_LTSts.posLS;
    else
        LevelShiftPval=0;
    end

    posAR=seqp(contains(rownam,'b_auto'));
    % Initialize pvalue of last AR component to be zero.
    LastARPval=0;
    if ~isempty(posAR)
        % Position of the last element of the AR component
        posLastAR=max(seqp(contains(rownam,'b_auto')));
        if posLastAR>1
            LastARPval=out_LTSts.Btable{posLastAR,'pval'};
        end
    end

    % Group all p-values into a vector
    Pvalall = [LastTrendPval;...
        LastHarmonicPval;...
        maxPvalX; LastVarAmplPval;...
        LevelShiftPval; LastARPval];

    % Start of model reduction (step 2b)
    [maxPvalall,indmaxPvalall]=max(Pvalall);

    if maxPvalall>thPval
        switch indmaxPvalall
            case 1
                % if indmaxPvalall == 1
                % Remove from model the last term of the trend component
                if msg==1 || plots==1
                    removed =['Removing trend of order ' num2str(model.trend)];
                end
                model.trend=model.trend-1;
            case 2
                % elseif indmaxPvalall ==2
                % Remove from model the last term of the seasonal component, that
                % is remove last harmonic
                if msg==1 || plots==1
                    tmp = num2str(model.seasonal);
                    tmp = tmp(end);
                    removed =['Removing harmonic number ' tmp];
                end
                model.seasonal= model.seasonal-1;
                % If the last seasonal component has been removed and there
                % are still terms of non linear seasonality, remove them
                strseaso=num2str(model.seasonal);
                if length(strseaso)==3 && strseaso(end)=='0'
                    if msg==1 || plots==1
                        removed = strcat(removed,'. Removing also amplitude of all orders of seas. comp.');
                    end
                    model.seasonal=0;
                end
            case 3
                % Remove from model the non signif expl var
                    if msg==1 || plots==1
                        removed =['Removing expl. variable number ' num2str(posmaxPvalX)];
                    end
                model.X(:,posmaxPvalX)= [];
            case 4
                % elseif indmaxPvalall ==4
                % Remove from model the high order term of non linear seasonality
                if msg==1 || plots==1
                    strseaso=num2str(model.seasonal);
                    removed = ['Removing amplitude of order ' strseaso(1) ' of seas. comp.'];
                end
                model.seasonal= model.seasonal-100;
            case 5
                % elseif indmaxPvalall ==5
                % Remove from model the level shift component
                model.lshift=0;
                if msg==1 || plots==1
                    removed ='Remove level shift component';
                end
            case 6
                if msg==1 || plots==1
                    strAR=num2str(model.ARp(end));
                    removed = ['Removing AR component of order ' strAR];
                end
                model.ARp=model.ARp(1:end-1);
            otherwise
                %else
        end

        if msg==1 || plots==1
            disp(removed)
        end


        % The instruction below should not be necessary
%         if model.lshift(1)~=0 
%             model.lshift=posLS;
%         end

        % Re-run the model but do not re-estimate the position of the
        % level shift
        [out_LTSts]=LTSts(out_LTSts.y,'model',model,'nsamp',nsamp,...
            'plots',plots,'msg',msg,'dispresults',dispresults,'h',h1,'SmallSampleCor',1);

        if plots==1
            a=gcf;
            title(a.Children(end),{['trend = ' num2str(model.trend) ...
                ', seas = ' num2str(model.seasonal) ...
                ' every ' num2str(model.s) ...
                ' months', ', LS = ' num2str(posLS), ...
                ', X = ' num2str(size(model.X,2)-1) ],num2str(removed)});
            if model.lshift(1)~=0
                hold on;
                line([posLS posLS],[min(out_LTSts.y),max(out_LTSts.y)],...
                    'Color','black','LineStyle','--','Linewidth',1);
            end
        end
    else
        % All the variables are significant, variable selection procedure
        % stops
        AllPvalSig=1;
    end

end

% Do a final refinement for the autoregressive component (if it is present)
ARfinalrefinement=false;
if ARfinalrefinement==true && ~isempty(model.ARp)
    % 1) Estimate the model without the autoregressive component using final
    % values of seasonal component, level shift and trend;
    % 2) Find the outliers and use fitted values for the units declared as
    % outliers for the autoregressive component;
    % 3) Final call to LTSts to re-estimate the model adding the specification for
    % the autoregressive component found before and using yhat for y lagged
    % for the units declared as outliers.
    modelfinref=model;
    modelfinref.ARp=[];
    [out_LTSts]=LTSts(out_LTSts.y,'model',modelfinref,'nsamp',nsamp,...
        'plots',0,'msg',msg,'dispresults',dispresults,'SmallSampleCor',1);

    tentOutForAR=out_LTSts.outliers(out_LTSts.outliersPval<0.001);
    yhatout=out_LTSts.yhat(tentOutForAR);
    ARtentout=[tentOutForAR yhatout];
    model.ARtentout=ARtentout;

    % re-estimate final model
    [out_LTSts]=LTSts(out_LTSts.y,'model',model,'nsamp',nsamp,...
        'plots',0,'msg',msg,'dispresults',dispresults,'SmallSampleCor',1);
end


if isempty(model.ARp)
    model.ARp = 0;
end

reduced_est   = model;
reduced_model = out_LTSts;

if msg==1
    disp('The final selected model has these parameters:')
    disp(reduced_model);
end

[msgstr, ~] = lastwarn;

end
%FScategory:REG-Regression
