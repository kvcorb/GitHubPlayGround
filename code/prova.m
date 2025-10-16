%% esercizio 1.12

%  sezione dati
ei=[0 10 100 200 300 332 400]';
es=[10 100 200 300 332 400 1000]';
ni=[1430 4156 3614 720 55 15 1]';

% opzionale
dati=[ei es ni]
writematrix(dati,'dati.xlsx')

%% ampiezze delle classi

% ampiezze delle classi -> densità di frequenza
ai=(es-ei)
% punti centrali delle classi -> media, standard deviation, Fisher.
pc=((ei+es)./2)

% classi -> quantili  
classi=[ei(1,1); es];

% secondo quartile = mediana
q2=0.50;

%% ricostruiamo il boxplot

% permette di fissare il seme dei numeri casuali
rng(1234);

%% ricostruisco i dati per l'istogramma
c1 = randi([0 10],1430,1);
c2 = randi([10 100],4156,1);
c3 = randi([100 200],3614,1);
c4 = randi([200 300],720,1);
c5 = randi([300 332],55,1);
c6 = randi([332 400],15,1);
c7 = randi([400 1000],1,1);

% ricombino in un unico vettore colonna
datiricostruiti=[c1; c2;c3;c4;c5;c6;c7];
% alternativa....
datiricostruiti=[c1' c2' c3' c4' c5' c6' c7']';

%%

% aggiungo un valore < 1 agli estremi delle classi (esclusi gli estremi)
% in modo che il conteggio sia esatto
classig=[classi(1); classi(2:end-1)+1; classi(end)];

% disegnamo l'istogramma con le frequenze
h=histogram(datiricostruiti,classig)

%% calcolo gli indicatori

% media di ordine 1 -> media aritmetica ponderata
M=GUIpowermean(pc,1,ni)
media=M.mean

% mediana di un fenomeno continuo -> 'DiscreteData',false
Me=GUIquantile(classi ,q2, 'freq',ni,'DiscreteData',false)
mediana=Me.quantile

% standard deviation
sd1=GUIstd(pc,ni)
%standdev=sd1.std

% scostamenti dalla mediana
% Sme -> flag=2
flag=2;

Sme=GUImad(classi,flag,ni,'DiscreteData',false)

% calcolo AS1 (Pearson)
AS1=(media-mediana)/sd1.std


% calcolo AS2 (Gini)
AS2=(media-mediana)/Sme.mad



% MAD -> flag=1 (non richiesto!)
flag=1;

mad1=GUImad(classi,flag,ni,'DiscreteData',false)



%% istogramma

% calcolo classi in modo alternativo
classi=unique([ei es])

% calcolo la densità di frequenza
densfreq=ni ./ ai;

% classe modale?

[~,pos]=max(densfreq)
Mo=(classi(pos)+classi(pos+1))/2


% con barvariablewidth

barVariableWidth(densfreq, classi)

% Calcolo indice di asimmetria di Fisher (biased Version)
flagf=1;
ifisher=GUIskewness(pc, flagf, ni)

gamma=ifisher.gamma