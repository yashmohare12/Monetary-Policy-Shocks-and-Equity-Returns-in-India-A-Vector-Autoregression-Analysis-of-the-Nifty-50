clc;
clear;
close all;

% Import dataset
data = readtable("project.csv");

% Display first 10 observations
disp(head(data,10));

% Display variable names
disp(data.Properties.VariableNames);

% Check number of observations
disp(height(data));

% Check missing values
disp(sum(ismissing(data)));



% Convert date to datetime if necessary
data.Date = datetime(data.Date);

% Sort dates
data = sortrows(data,"Date");

% Remove missing observations
data = rmmissing(data);

% Check again
disp(data);


% Nifty returns
Nifty_Return = 100 * diff(log(data.Nifty));

% USD/INR percentage change
Exchange_Return = 100 * diff(log(data.USDINR));

% Repo rate changes
Repo_Change = diff(data.Repo);


% Crude oil percentage returns
Crude_Return = 100 * diff(log(data.Brent));
% Create transformed variables
Y = table();

Y.Date = data.Date(2:end);

Y.Nifty_Return = Nifty_Return;
Y.Repo_Change = Repo_Change;
Y.Exchange_Return = Exchange_Return;

Y.Crude_Return = Crude_Return;

disp(head(Y,10));



figure;

plot(Y.Date,Y.Nifty_Return);

title("Nifty 50 Monthly Returns");
xlabel("Date");
ylabel("Return (%)");

grid on;











figure;

plot(Y.Date,Y.Repo_Change);

title("Monthly Changes in Repo Rate");
xlabel("Date");
ylabel("Repo Rate Change");
grid on;



X = Y{:,2:end};

Mean_Value = mean(X);
Std_Deviation = std(X);
Minimum_Value = min(X);
Maximum_Value = max(X);

Summary = table(Mean_Value', ...
    Std_Deviation', ...
    Minimum_Value', ...
    Maximum_Value', ...
    'VariableNames', ...
    {'Mean','StandardDeviation','Minimum','Maximum'}, ...
    'RowNames',Y.Properties.VariableNames(2:end));

disp(Summary);

CorrMatrix = corr(X);

disp(CorrMatrix);

figure;

heatmap(Y.Properties.VariableNames(2:end), ...
    Y.Properties.VariableNames(2:end), ...
    CorrMatrix);

title("Correlation Matrix of Macroeconomic Variables");






%% ADF STATIONARITY TEST

for i = 1:size(X,2)

    [~,pValue,stat] = adftest(X(:,i),'Lags',1);

    fprintf('\nVariable: %s\n', ...
        Y.Properties.VariableNames{i+1});

    fprintf('ADF Statistic: %.4f\n',stat);
    fprintf('p-value: %.4f\n',pValue);

    if pValue < 0.05
        disp("Stationary: Reject unit root");
    else
        disp("Non-stationary: Cannot reject unit root");
    end

end


VARData = Y{:,{'Repo_Change','Crude_Return', 'Exchange_Return',   'Nifty_Return'}};



% Number of variables
k = size(VARData,2);

% VAR model with 2 lags
Mdl = varm(k,2);

% Estimate model parameters
EstMdl = estimate(Mdl,VARData);

% Display estimated model
disp(EstMdl);


% Generate impulse responses
[~,~,~] = irf(EstMdl,NumObs=12);

% IRF horizon
















%% IMPULSE RESPONSE FUNCTION

[IRF,Lower,Upper] = irf(EstMdl,NumObs=12);

% Nifty response to Repo Rate shock
Nifty_Repo_IRF = IRF(:,4,1);

% Match the number of IRF observations
horizon = 0:length(Nifty_Repo_IRF)-1;

figure;

plot(horizon,Nifty_Repo_IRF,'-o','LineWidth',1.5);

yline(0,'k--');

title("Nifty Response to Repo Rate Shock");

xlabel("Periods After Shock");

ylabel("Response of Nifty Returns");

grid on;


%% RESIDUAL DIAGNOSTICS

E = infer(EstMdl,VARData);

% Plot Nifty residuals
figure;

plot(E(:,4));

title("VAR Residuals - Nifty");

xlabel("Observation");

ylabel("Residual");

grid on;


%% LJUNG-BOX TEST FOR ALL VARIABLES

for i = 1:size(E,2)

    [h,pValue] = lbqtest(E(:,i));

    fprintf('\nResidual variable: %s\n', ...
        Y.Properties.VariableNames{i+1});

    fprintf('Ljung-Box h = %d\n',h);

    fprintf('Ljung-Box p-value = %.4f\n',pValue);

    if pValue > 0.05

        disp("No significant autocorrelation detected");

    else

        disp("Possible residual autocorrelation");

    end

end


%% VAR STABILITY

























% Plot residuals of Nifty
figure;

plot(E(:,4));

title("VAR Residuals - Nifty");
xlabel("Observation");
ylabel("Residual");

grid on;





% Test autocorrelation of Nifty residuals
[h,pValue] = lbqtest(E(:,4));

disp(h);
disp(pValue);