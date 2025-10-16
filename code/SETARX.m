function [out, reg, input] = SETARX(y, p, d, varargin)
%SETARX implements Threshold autoregressive models with two regimes
%
% Self Exciting Threshold AutoRegressive model (SETAR) with two regimes.
% Estimation with Conditional Least Squares.
% Depend on estregimeTAR, chkinputTAR, extendVEC.
%
% 
%<a href="matlab: docsearchFS('SETARX')">Link to the help function</a>
%
%
% Required input arguments:
%
%
%          y :  Response variable. Vector. Response variable, specified as
%               a vector of length n, where n is the number of
%               observations.
%               Missing values (NaN's) and infinite values (Inf's) are
%               allowed, since observations (rows) with missing or infinite
%               values will automatically be excluded from the
%               computations. Data type - double.
%          p :  autoregressive order of y in regimes. Scalar. If
%               p = 0, the AR part is not present in the regimes, so an
%               error is given in the case 'X' and 'Z' are empty and
%               'intercept' is false.
%               Data type - non-negative integer.
%          d :  lag of the threshold variable $y_{(t-d)}$. Scalar. Data
%               Data type - positive integer.
%
% Optional input arguments:
%
%       trim :  Minimum fraction of observations contained in each regime.
%               Scalar. The trimming parameter should be set between 0.05
%               and 0.45. The fraction of observations to trim from tails
%               of the threshold variable, in order to ensure a sufficient
%               number of observations around the true threshold parameter
%               so that it can be identified (usually set between 0.10 and
%               0.15). Default is 0.15. If the number of observations to be
%               trimmed is less than the total number of regressors, an
%               error is given.
%               Example - 'trim', 0.10
%               Data Types - double
%
%  intercept :  Indicator for constant term. true (default) | false.
%               Indicator for the constant term (intercept) in the fit,
%               specified as the comma-separated pair consisting of
%               'Intercept' and either true to include or false to remove
%               the constant term from the model.
%               Example - 'intercept',false
%               Data Types - boolean
%
%          X :  Data matrix of explanatory variables. Matrix of exogenous
%               regressors of dimension n x k1, where k1 denotes the number
%               of regressors excluding the intercept. Rows of X represent
%               observations, and columns represent variables. Each entry
%               in y is the response for the corresponding row of X. By
%               default, there is a constant term in the model, unless you
%               explicitly remove it using input option intercept, so do
%               not include a column of 1s in X. Missing values (NaN's) and
%               infinite values (Inf's) are allowed, since observations
%               (rows) with missing or infinite values will automatically
%               be excluded from the computations. 
%               Example - 'X',randn(n,k1)
%               Data Types - double
%
%          Z :  Deterministic variables (including dummies). Matrix of
%               deterministic regressors of dimension n x k2, where k2
%               denotes the number of regressors excluding the intercept.
%               Rows of Z represent observations, and columns represent
%               variables. Each entry in y is the response for the
%               corresponding row of Z. By default, there is a constant term in the
%               model, unless you explicitly remove it using input option
%               intercept, so do not include a column of 1s in Z. Missing
%               values (NaN's) and infinite values (Inf's) are allowed,
%               since observations (rows) with missing or infinite values
%               will automatically be excluded from the computations. 
%               Example - 'Z',randn(n,k2)
%               Data Types - double
%
%
%  Output:
%
%
%
%       out : A structure with the results of the SETARX model estimation
%               containing the following fields:
%        out.regime1 =  A sub-substructure containing the results of the OLS estimation of the linear
%                              regression model applied to the data in
%                              regime 1. The estimation is performed with
%                              the function estregimeTAR.
%                              Additional details are in the description
%                              of the outputs in the output structure reg.
%        out.regime2 =  A sub-substructure containing the results of the
%                             OLS estimation of the linear
%                              regression model applied to the data in
%                              regime 2. The estimation is performed with
%                              the function estregimeTAR (see sections
%                              'Outputs' and 'More about' of estregimeTAR).
%   out.rmv_col_loop =  Warnings collected for regimes 1 and 2 in the loop for the search of the
%                      optimal threshold value. Matrix of strings of
%                      dimension n x 2. Warnings show the indices of
%                      columns removed from the matrix of regressors before
%                      the model estimation. Columns containing only zeros
%                      are removed. Then, to avoid multicollinearity, in
%                      the case of presence of multiple non-zero constant
%                      columns, the code leave only the first constant
%                      column.
%         out.thrhat =  Estimated threshold value. Scalar. It is the threshold value that minimizes
%                              the joint RSS.
%     out.thrvar_ord =  Index series after reorder of threshold variable yd. Vector.
%           out.sigmaj_2 =  Estimated residual variance of SETARX model. Scalar.
%           out.RSSj =  Joint Residual Sum of Squared of SETARX model. Scalar.
%          out.yjhat =  Fitted values of SETARX model. Vector.
%           out.resj =  Residuals of the SETARX model. Vector.
%       out.yjhat_full = Fitted values of SETARX model with observations
%                       (rows) with missing or infinite
%                         values reinserted as NaNs. This is to obtain the
%                         same length of the initial
%                        input vector y defined by the user.
%      out.resj_full =  Residuals of the SETARX model with observations
%                       (rows) with missing or infinite
%                       values reinserted as NaNs. This is to obtain the
%                       same length of the initial input vector defined by
%                       the user.
%
%    reg : A structure with the results of the OLS estimation of
%               the linear regression model (benchmark), containing the following fields.
%         reg.beta =  Estimated parameters of the regression model. Vector.
%                     See out.covar.
%           reg.se =  Estimated heteroskedasticity-consistent (HC) standard
%                    errors. Vector.
%        reg.covar =  Estimated variance-covariance matrix. Matrix. It is
%                     the heteroskedasticity-consistent (HC) covariance
%                      matrix. See section 'More about'.
%      reg.sigma_2 =  Estimated residual variance. Scalar.
%         reg.yhat =  Fitted values. Vector.
%          reg.res =  Residuals of the regression model. Vector. 
%          reg.RSS =  Residual Sum of Squared. Scalar. 
%          reg.TSS =  Total Sum of Squared. Scalar.
%          reg.R_2 =  R^2. Scalar.
%          reg.n   =  Number of observations entering in the estimation.
%                    Scalar. 
%           reg.k =  Number of regressors in the model left after
%                    the checks. It is the number of
%                    betas to be estimated by OLS. The betas
%                    corresponding to the removed columns of X will be
%                    set to 0 (see section 'More about' of
%                    estregimeTAR). Scalar.
%      reg.rmv_col =  Indices of columns removed from X before the model
%                       estimation. Scalar or vector.
%                         Columns containing only zeros are removed. Then,
%                         to avoid multicollinearity, in the case of
%                         presence of multiple non-zero constant columns,
%                         the code leave only the first constant column
%                         (see section 'More about' of estregimeTAR).
%   reg.rk_warning =  Warning for skipped estimation. String. If the matrix
%                       X is singular after the
%                         adjustments, the OLS estimation is skipped, the
%                         parameters are set to NaN and a warning is
%                         produced.
%    reg.yhat_full =  Fitted values of the estimated linear regression
%                       model with observations (rows) with
%                         missing or infinite values reinserted as NaNs.
%                         This is to obtain the same length of the initial
%                         input vector y defined by the user.
%     reg.res_full = Residuals of the estimated linear regression model
%                       with observations (rows) with
%                         missing or infinite values reinserted as NaNs.
%                         This is to obtain the same length of the initial
%                         input vector y defined by the user.
%
%  input :  A structure containing the following fields.
%         input.y = Response without missing and infs. Vector. The new
%               response variable, with observations (rows) with missing or infinite values
%                excluded.
%         input.X = Predictor variables without infs and missings. Matrix.
%                   The new matrix of explanatory variables, with missing
%                   or infinite values excluded, to be used for the model
%                   estimation. It is the matrix [L X Z intercept] where L
%                   is the lagged matrix n x p of y (if p > 0), X is the
%                   matrix of exogenous regressors defined by the user, Z
%                   is the matrix of deterministic regressors and the last
%                   column is the intercept (if any).
%         input.yd = Threshold variable without missing and infs. Vector. The
%                   new threshold variable,
%                  with observations (rows) with missing or infinite
%                  values excluded.
%       input.rmv_obs = Indices of removed observations/rows (because of
%                   missings or infs). Scalar vector.
%    input.y_full = Response y after adjustments by chkinputTAR BUT with
%                   observations (rows) with missing or infinite values
%                   included.
%    input.X_full = Matrix X after adjustments by chkinputTAR BUT with
%                 observations (rows) with missing or infinite values included.
%   input.yd_full = Threshold variable after adjustments by chkinputTAR BUT
%                 with observations (rows) with
%                 missing or infinite values included.
%
%  More about (fix this section):
%
% Given a time series $y_t$, a two-regime Self-Exciting Threshold
% Auto Regressive model SETARX($p$,$d$) with exogenous regressors is specified as
% \begin{equation}\label{eqn:setar}
% y_t=
% \begin{cases}
% {\bf x}_{t} {\boldsymbol{\beta}}_1 + {\bf z}_{t} {\boldsymbol{\lambda}}_1 + \varepsilon_{1t}, \hspace{0.5cm} \textrm{if} \hspace{0.5cm} y_{t-d}\leq \gamma \\
%     {\bf x}_{t} {\boldsymbol{\beta}}_2 + {\bf z}_{t} {\boldsymbol{\lambda}}_2 + \varepsilon_{2t}, \hspace{0.5cm} \textrm{if} \hspace{0.5cm} y_{t-d}> \gamma
%         \end{cases}
%     \end{equation}
% for $t=\max(p,d),...,N$, where $y_{t-d}$ is the threshold variable
%         with $d\geq 1$ and $\gamma$ is the threshold value. The relation
%     between $y_{t-d}$ and $\gamma$ states if $y_t$ is observed in regime
%     1 or 2. ${\boldsymbol{\beta}}_j$ is the vector of auto-regressive parameters
%     for regime $j=1,2$ and ${\bf x}_{t}$ is the $t$-th row of the
%         $(N\times p)$ matrix ${\bf X}$ comprising $p$ lagged variables of
%         $y_t$. ${\boldsymbol{\lambda}}_j$ is the vector of parameters corresponding
%         to exogenous regressors and/or dummies contained in the $(N \times
%         r)$ matrix ${\bf Z}$ whose $t$-th row is ${\bf z}_t$. Errors
%         $\varepsilon_{1t}$ and $\varepsilon_{2t}$ are assumed to be independent and to follow
%         distributions $\mathrm{iid}(0,\sigma_{\varepsilon,1})$ and
%         $\mathrm{iid}(0,\sigma_{\varepsilon,2})$ respectively.
%
%         \subsection{Estimation of SETAR models}
%         \label{sec:2.1}
%
%         In general, the value of the threshold $\gamma$ is unknown, so that
%         the parameters to estimate become ${\boldsymbol{\theta}}_1=({\boldsymbol{\beta}}^{\prime}_1, {\bf\lambda}^{\prime}_1)^{\prime}$, ${\boldsymbol{\theta}}_2=({\boldsymbol{\beta}}^{\prime}_2,{\bf\lambda}^{\prime}_2)^{\prime}
%         $, $\gamma$, $\sigma_{\varepsilon,1}$ and $\sigma_{\varepsilon,2}$.
%
%         Parameters can be estimated by sequential conditional least squares. 
%         For a fixed threshold $\gamma$ the observations may be divided into two samples 
%         $\{y_t |y_{t-d}\leq \gamma\}$ and $\{y_t |y_{t-d}> \gamma\}$: 
%         the data can be denoted respectively as 
%         $\mathbf{y}_j=(y_{ji_1},y_{ji_2},...,y_{ji_{N_j}})^{\prime}$ in regimes $j=1,2$, 
%         with $N_1$ and $N_2$ the regimes sample sizes and $N_1+N_2=N-\max(p,d)$.
%
%     Parameters ${\boldsymbol{\theta}}_1$ and ${\boldsymbol{\theta}}_2$ can be estimated by OLS as
%     \begin{equation}\label{eqn:par}
%     \hat{\boldsymbol{\theta}}_j=\left({\mathbf{X}^*_j}^{\prime}\mathbf{X}^*_j\right)^{-1}{\mathbf{X}^*_j}^{\prime}\mathbf{y}_j\,
%     \end{equation}
%       for $j=1,2$ where $\mathbf{X}^*_j=(\mathbf{X}_j,\mathbf{Z}_j)=(({\bf x}_{ji_1}^{\prime},...,{\bf x}_{ji_{N_j}}^{\prime})^{\prime},({\bf z}_{ji_1}^{\prime},...,{\bf z}_{ji_{N_j}}^{\prime})^{\prime})$ 
%       is the $(N_j \times (p+r))$ matrix of regressors for each regime. The variance estimates can be calculated as
%         $\hat{\sigma}_{\varepsilon,j}={\bf r}_j^{\prime}{\bf r}_j /(N_j - (p+r))$, with ${\bf r}_j={\bf y}_j-\mathbf{X}^*_j\hat{\boldsymbol{\theta}}_j$.
%
%     The least square estimate of $\gamma$ is obtained by minimizing the joint residual sum of
%     squares
%     \begin{equation}\label{eqn:gamma}
%     \gamma=\arg\min_{\gamma\in\Gamma}\sum_{j=1}^2 {\bf r}_j^{\prime}{\bf r}_j
%     \end{equation}
% over a set $\Gamma$ of allowable threshold values so that each
% regime contains at least a given fraction $\varphi$ (ranging from
% 0.05 to 0.3) of all observations.
%
%
% See also: LTSts
%
% References:
%
% Franses and van Dijk (2000), "Nonlinear Time Series Models in Empirical Finance",
%    Cambridge: Cambridge University Press.
%
% Grossi, L. and Nan, F. (2019), Robust forecasting of electricity prices:
%    simulations, models and the impact of renewable sources, "Technological
%    Forecasting & Social Change", Vol. 141, pp. 305-318.
%    https://doi.org/10.1016/j.techfore.2019.01.006
%
%
% Copyright 2008-2025.
% Written by FSDA team
%
%
%<a href="matlab: docsearchFS('SETARX')">Link to the help function</a>
%
%
%$LastChangedDate:: 2020-06-09 17:55:46 $: Date of the last commit
%
% Examples:

%{
    %% Example 1: Estimation from simulated data.
    %  $\beta_1=(0.7, -0.5, -0.6, 0.3, 0.3)^{\prime}$ and ...
    %  $\beta_2=(-0.1, -0.5, 0.6, 0.4, 0)^{\prime}$.
    % SETAR with all the default options.
    % Use simulated data.
    rng('default')
    rng(10)
    n = 50;
    y = randn(n,1);
    X1 = randn(n,2);
    for i = 3:n
        y(i) = (y(i-2) < 0.5)*(0.3+0.7*y(i-1)-0.5*y(i-2)-0.6*X1(i,1)+0.3*X1(i,2))+...
        (y(i-2) >= 0.5)*(-0.1*y(i-1)-0.5*y(i-2)+0.6*X1(i,1)+0.4*X1(i,2));
    end
    p = 2;
    d = 2;
    [out, reg, input] = SETARX(y, p ,d, 'X',X1);
%}

%{
    % Example 2: Estimation from simulated data in example 1 with an extra constant column as regressor.
     n = 50;
    y = randn(n,1);
    X1 = randn(n,2);
    X2 = [repmat(0.3,n,1) X1];
    p = 2;
    d = 2;
    [out2] = SETARX(y, p ,d, 'X',X2);
%}

%{
    % Example 3: variant from example 1.
    % Estimation from simulated data of example 1 with an extra column as regressor, half zeros
    % and half ones. This will produce a warning (column of zeros removed) during the loop for the 
    % estimation of the threshold value. Check out3.setarx.rmv_col_loop.
     n = 50;
    y = randn(n,1);
    X1 = randn(n,2);
    p = 2;
    d = 2;
    X3 = [[repmat(0,25,1);repmat(1,25,1)] X1];
    [out3] = SETARX(y, p ,d, 'X',X3);
%}


%% Beginning of code

if nargin<1 || isempty(y)==1
    error('FSDA:SETARX:MissingInputs','Input vector y not specified.');
end

if nargin<2 || isempty(p)==1
    error('FSDA:SETARX:MissingInputs','Input scalar p not specified.');
end

if nargin<3 || isempty(d)==1
    error('FSDA:SETARX:MissingInputs','Input scalar d not specified.');
end

% Set up values for default model.
trim      = 0.15; % default trimming parameter.
intercept = true; % include intercept.
X         = [];   % no continuous explanatory variables.
Z         = [];   % no deterministic variables.

if nargin > 3
    options = struct('trim',trim, 'intercept',intercept, 'X',X, 'Z',Z);
    % Checks on user options.
    UserOptions = varargin(1:2:length(varargin));
    if ~isempty(UserOptions)
        % Check if number of supplied options is valid.
        if length(varargin) ~= 2*length(UserOptions)
            error('FSDA:SETARX:WrongInputOpt','Number of supplied options is invalid. Probably values for some parameters are missing.');
        end
        % Check if user options are valid options.
        aux.chkoptions(options,UserOptions)
    end
    
    % Write in structure 'options' the options chosen by the user.
    for i=1:2:length(varargin)
        options.(varargin{i})=varargin{i+1};
    end
    
    % Set user options.
    trim = options.trim;
    intercept = options.intercept;
    X = options.X;
    Z = options.Z;
end


% Check if p is non negative and d is positive.
if p < 0
    error('FSDA:SETARX:WrongInput','p must be non negative.');
end
if d <= 0
    error('FSDA:SETARX:WrongInput','d must be positive.');
end

% Check if there is at least one regressor.
if isequal(p, 0) && isempty(X) && isempty(Z) && isequal(intercept, false)
    error('FSDA:SETARX:WrongInput','The model must contain at least one regressor. Change p, intercept, X and/or Z.');
end

% p and d must be integers.
p = round(p);
d = round(d);

n = length(y);
L = []; % L is empty if p = 0.
% L = lagged matrix n x p of y, if p > 0.
if p > 0
    L = NaN(n, p);
    for ARorder = 1:p
        L(:,ARorder) = [NaN(ARorder, 1); y(1:n-ARorder)];
    end
end

% Merge the matrices into one after a check on the dimension (number of observations-rows).
if size(X,1) > 0 && size(X,1) ~= n
    error('FSDA:SETARX:NxDiffNy','Number of observations in X and y not equal.');
end

if size(Z,1) > 0 && size(Z,1) ~= n
    error('FSDA:SETARX:NzDiffNy','Number of observations in Z and y not equal.');
end

% Merge matrices.
X = [L X Z];

% Threshold variable yd.
yd = [NaN(d, 1); y(1:n-d)];


% Checks on y, yd and X, remove NaNs and insert intercept.
[y, yd, X, n, k, rmv_obs, input_full] = aux.chkinputTAR(y, yd, X, intercept);
% n is the number of observations after removing NaNs and Infs.
% k=p+k1+k2(+1) is the total number of regressors (including intercept if any)
% after the checks for multiple constant columns and rank.
% rmv_obs are the indices of removed observations/rows (because of missings or infs).


% Checks on trim.
if trim < 0.05 || trim > 0.45
    error('FSDA:SETARX:WrongInput','Value of trim should be in [0.05, 0.45].');
end
ntrim = round(trim*n);
if ntrim < k
    error('FSDA:SETARX:WrongInput','Value of trim should be higher than %s.', round(k/n, 3));
end



%% Linear Regression as a benchmark

[benchreg] = estregimeTAR(y, X); % This function estimates a linear regression.

% Insert NaNs in the position of the removed observations (if any) for the full version of yhat and res.
if numel(rmv_obs)>0
    yhat_full = extendVEC(benchreg.yhat, rmv_obs, NaN);
    res_full = extendVEC(benchreg.res, rmv_obs, NaN);
else 
    yhat_full = benchreg.yhat;
    res_full = benchreg.res;
end



%% Estimate SETAR model

% Sort observations in y and X in ascending order based on the elements in yd (threshold variable).
XX=[y X yd];
[XXord, thrvar_ord] = sortrows(XX, size(XX,2));

% Initialize values for the loop.
RSSj = Inf(n,1);
thrval = Inf;
rmv_col_loop = NaN(n,2);

% Estimate the threshold. The direction of the loop is important in the case of non-unique threshold values.
% Hence regime 1 is for yd <= thrval.
for i = n-ntrim : -1 : ntrim+1
    
    disp(['Searching for the optimal threshold: loop ' num2str(n-ntrim-i+1) ' of ' num2str(n-2*ntrim)]);
    
    if XXord(i, end) == thrval
        % If the threshold doesn't change from the previous step, the code doesn't recalculate the regimes.
        RSSj(i) = RSSj(i+1);
    else
        % Fix the threshold value.
        thrval = XXord(i, end);
        
        % Estimate regime 1.
        y1 = XXord(1:i, 1);
        X1 = XXord(1:i, 2:end-1);
        [regime1] = estregimeTAR(y1, X1);
        
        % Estimate regime 2.
        y2 = XXord(i+1:n,1);
        X2 = XXord(i+1:n,2:end-1);
        [regime2] = estregimeTAR(y2, X2);
        
        % Calculate the joint Residual Sum of Squares.
        RSSj(i) = regime1.RSS+regime2.RSS;
    end
    
    % Save a warning if in the loop some columns have been removed in one of the regimes.
    if ~isempty(regime1.rmv_col)
        rmv_col_loop(i,1) = sprintf(['Warning loop ' num2str(i) ': columns ' num2str(regime1.rmv_col) ' have been removed from the explanatory matrix X for the parameter estimation of regime 1.']);
    end
    if ~isempty(regime2.rmv_col)
        rmv_col_loop(i,2) = sprintf(['Warning loop ' num2str(i) ': columns ' num2str(regime2.rmv_col) ' have been removed from the explanatory matrix X for the parameter estimation of regime 2.']);
    end
    
    
end


% Find the threshold value that minimizes the joint RSS.
[minRSSj,posRSSj] = min(RSSj);
thrhat = XX(max(posRSSj), end); % max is used in the case of non-unique solutions (non-unique threshold values).

% Estimate regime 1 for the optimal solution.
y1 = XXord(1:max(posRSSj), 1);
X1 = XXord(1:max(posRSSj), 2:end-1);
[regime1] = estregimeTAR(y1, X1);

% Give a warning if some variables were removed from the regression model for regime 1.
if ~isempty(regime1.rmv_col)
    disp(['Warning regime 1: columns ' num2str(regime1.rmv_col) ' have been removed from the explanatory matrix X for the parameter estimation.']);
end

% Estimate regime 2 for the optimal solution.
y2 = XXord(max(posRSSj)+1:n,1);
X2 = XXord(max(posRSSj)+1:n,2:end-1);
[regime2] = estregimeTAR(y2, X2);

% Give a warning if some variables were removed from the regression model for regime 2.
if ~isempty(regime2.rmv_col)
    disp(['Warning regime 2: columns ' num2str(regime2.rmv_col) ' have been removed from the explanatory matrix X for the parameter estimation.']);
end


% Merge the results of the two regimes to obtain the joint fitting, residuals and sigma^2.
yjhat = [regime1.yhat; regime2.yhat];
resj = [regime1.res; regime2.res];
sigmaj_2 = minRSSj/(regime1.n+regime2.n-regime1.k-regime2.k);


% Reorder yjhat and resj using the index of original positions thrvar_ord.
yjhat = yjhat(thrvar_ord); % CHECK IF WORKS PROPERLY
resj = resj(thrvar_ord);


% Insert NaNs in the position of the removed observations for the full version of yjhat and resj.
if numel(rmv_obs)>0
    yjhat_full = extendVEC(yjhat, rmv_obs, NaN);
    resj_full = extendVEC(resj, rmv_obs, NaN);
else 
    yjhat_full = yjhat;
    resj_full = resj;
end



%% Structured outputs
input=struct;

input.y = y;
input.X = X;
input.yd = yd;
input.rmv_obs = rmv_obs;
input.y_full = input_full.y;
input.X_full = input_full.X;
input.yd_full = input_full.q;


reg = benchreg;

reg.yhat_full = yhat_full;
reg.res_full = res_full;

out = struct;

out.regime1 = regime1;
out.regime2 = regime2;
out.rmv_col_loop = rmv_col_loop;
out.thrhat = thrhat;
out.thrvar_ord = thrvar_ord;
out.sigmaj_2 = sigmaj_2;
out.RSSj = minRSSj;
out.yjhat = yjhat;
out.resj = resj;
out.yjhat_full = yjhat_full;
out.resj_full = resj_full;



end
%FScategory:REG-Regression
