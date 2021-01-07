### A Pluto.jl notebook ###
# v0.3.1
# ⋐⋑ c4a8badc-6711-11ea-2456-1d08737fa0c4
md"# _Chapter six:_ Results

_In this final chapter, we discuss the results of applying our theory to the SciGRID dataset. We would like to reiterate that this data is aggregated from different sources, most of which are_ not _physical measurements, but 'educated guesses'._

## Line covariance
By incorporating bus covariances in our model (which result from correlated weather), we hope to find new structure in the line covariances. 
To assess the effect of estimating bus covariances, we compare three possible bus covariance matrices:

1. _The identity matrix_: all bus injections are independently Gaussian distributed with the same variance. (They are almost IID, but their means differ.)
1. _The diagonal of estimated variances_: all bus injections are independently Gaussian distributed, but their variances and means differ.
1. _The estimated covariances_: the vector of bus injections is (multivariate) Gaussian distributed. All bus injections are, in general, dependent on each other, and their variances and means differ.

It is well known that local changes to the grid structure have long-range effects. For example, Witthaut and Timme (2013) showed that _adding_ a new line to a heavily congested, but stable network can cause the failure of another line, possibly far away from the added line. This is reflected in our model by the fact that line currents have non-zero covariance, even when bus injections are independently distributed. (In this case, $\Sigma_{f} = FIF^* = FF^*$, which is generally not a diagonal matrix.) Figure 6.4 and Figure 6.5 show the covariances of all lines, relative to a chosen line. We see that covariance is generally high for lines that are close, but there are some clear exceptions. There seems to be a general trend that lines are highly (positively or negatively) correlated when they are close, and _oriented in the same direction_ (e.g. East-West) as the chosen line.

![a](https://i.imgur.com/EEZqJZv.png)

## State
Our dataset contains hourly values for load and stochastic (wind and solar) generation for the year 2011. Deterministic generation is estimated using the OPF algorithm, as implemented by `PyPSA`, a Python package designed for this purpose. Following common practice, we first multiply all line thresholds by a **contingency factor**: $0.70$. This forces the optimisation process to leave a safety margin at every line, and also accounts for the error of using the DC approximation. Figure 6.2 shows the resulting injection at 1 January 2011 at 11:00. Line currents can then be computed using the LPF.

## Bus covariance
As discussed in Section 4.3, we estimate the bus covariance matrix from historical errors in our forecast. We find _high_ covariances among nodes, which we expected from our preliminary analysis. Because renewable generation data is extrapolated directly from (coarse) weather data, the generation series of nearby buses are almost identical. 

The covariance of buses, calculated using the difference series, is visualised in Figure 6.2.



The covariance of a random pair of lines is relatively high when their physical separation (measured either in kilometres or in graph distance) is low. Because weather is correlated, even at high distance, using the bus full covariance might result in higher covariances between lines with high separation. (This was concluded by \cite{Nesti2018emergentfailures}.)"

# ⋐⋑ 719311ac-6712-11ea-26f0-23e6e4c4af6d
md"Using a different bus covariance matrix will likely result in a overall increase or decrease of line covariances. Note, however, that scaling the covariance matrix \emph{uniformly} does change absolute overload probabilities, but it does not change the \emph{ranking} of most vulnerable lines, and it does not change most likely injection: a uniform factor in $\mat{\Sigma}_p$ disappears in Equation (\ref{eq:mostlikelyinjection}).

This makes it difficult to compare the three bus covariance matrices, as any absolute difference in line covariance should be ignored. Instead, we will examine the covariance of two lines, \emph{relative to their own variances}. This way, the effect of any absolute, proportional increase in covariance is avoided. First, let us choose a number of lines, and examine the covariances of all other lines with the chosen line, relative to its variance. 

In particular, we are interested in the decay of covariance over distance. \cite{Jung2016} studied the decay of the Line Addition Distribution Factor (difference in flow after adding a line) over distance, also using the SciGRID network. This is not the same as covariance, of course, but both are measures of the \emph{global effect} of local changes in flow. They first determined the largest 2-connected component of the network, and removed all other lines from the model. In the remaining network, they studied the 880 possible additions of short new lines, and found a general \emph{exponential} decay of change in currents as a function of graph distance.

To study the decay of covariance, we collect the geographical separation and covariance (resulting from the three possible bus covariance matrices) of $10^5$ random pairs of lines in the network. Because of power flow physics, these covariances are highly spread out. However, when averaging the covariances in groups of $25 \, \si{\kilo\metre}$ (Figure~\ref{fig:linecovdecay}), we find are able to see the differences in decay. 

\begin{figure}
\centering
\includegraphics[width=\textwidth]{img/covariance_linepairs_with_average.pdf}
\caption{\label{fig:linecovdecay} For $10^5$ random pairs of lines, the covariance and distance (between line centres) is shown, for three possible bus covariance matrices. The averages (over $25 \, \si{\kilo\metre}$) show that correlated buses increase long-range correlations in line flows. Covariances are normalised using average line variance.}
\end{figure}

By doing so, we find an important result. When we model bus injections to be uncorrelated (first two graphs in Figure~\ref{fig:linecovdecay}), we find \emph{some} correlation in line flows, which are due to power flow physics.\footnote{As an example, consider the $n$-loop network. Here, two neighbouring lines are highly correlated, since they always transmit roughly the same amount of power. (The difference is the amount of power injected at their common node.)} On average, these correlations decrease as the distance between two lines increases, as shown by the red line.\footnote{We might expect this decay to be \emph{exponential} (based on the work of \cite{Jung2016}, for example), but this is not the case.} 
On the other hand, when we include \emph{covariances among bus injections} in our model (last graph in Figure~\ref{fig:linecovdecay}), we find a \emph{relative increase in long-distance correlations of line flows}, compared to the uncorrelated case. This is one of the main results of \cite{Nesti2018emergentfailures}, which they demonstrate only on the $n$-loop network. Figure~\ref{fig:linecovdecay} validates that the result also holds for the SciGRID network.

Curiously, in the range $25\,\si{\kilo\meter}$ - $150\,\si{\kilo\meter}$, the average correlation of line flows \emph{increases} with higher line distances. The reason for this phenomenon is unclear, but one could investigate this further by examining line pairs of these short distances individually.

%\begin{figure}
%    \centering
%    \includegraphics[width=.4\textwidth]{img/load.png}
%    \caption{PLACEHOLDER: The load distribution of Germany at ???.}
%    \label{fig:loaddistribution}
%\end{figure}
%
\begin{figure}
    \centering
    \includegraphics[width=\textwidth]{img/installed_stochastic_capacity.pdf}
    \caption{Installed stochastic capacity per source: wind onshore, wind offshore, solar.}
    \label{fig:solarwind}
\end{figure}


\section{Most vulnerable lines}
Using the nominal injection at 1 January, 11:00, we compute the failure probability of each line. The 30 most vulnerable lines are given in Table~\ref{tab:results} (first two columns) and their positions are given in Figure~\ref{fig:nomflow_stdev_overload}. In the SciGRID dataset, lines are not numbered randomly. Rather, we find that two consecutive line numbers often correspond to two lines that are in close proximity. In the case of lines 651 and 652, for example, the two lines are connected in \emph{series}. As a consequence of power flow physics, their line flows highly correlated.

We identify the same vulnerable lines as \cite{Nesti2018supplemental}, but the ranking is different. This can be attributed to two differences in approach. First, we have combined parallel lines,\footnote{all 30 most vulnerable lines were not part of a parallel combination} which changes the vulnerability order significantly. It is unclear why this changes the result. For comparison, the ranking that we get \emph{without} combining parallels was also computed, which is more similar that of \cite{Nesti2018supplemental}. The second major difference is the use of a different covariance matrix, although it is reassuring to see that the same lines are identified.

\subsection{Properties of vulnerable lines}
As can clearly be seen in Table~\ref{tab:results}, most lines that are vulnerable to emergent failures are nominally being used at 70\% percent of their capacity. (This is exactly the \emph{contingency factor} used in the LOPF calculation.) This is explained by the low standard deviations of line flows. In fact, when we scale the covariance matrix uniformly by a factor close to zero, this effect is exaggerated.\footnote{This is a \emph{large deviations} result of the normal distribution: if we have $X \, \sim \, \gaussdistr(0, \sigma^2)$, then the marginal distribution of $X \, \mid \, X \geq 1$ becomes increasingly concentrated around $1$ as $\sigma$ tends towards zero. See \eg \cite{Touchette2011}.}

The 10 most vulnerable lines are not significantly long or short. They average $43\,\si{\kilo\meter}$ (SD $30 \,\si{\kilo\meter}$), compared to $36\,\si{\kilo\meter}$ (SD $35 \,\si{\kilo\meter}$) for \emph{all} lines in the network. From Figure~\ref{fig:nomflow_stdev_overload} we can make the interesting observation that vulnerable lines are generally oriented radially towards the \emph{Ruhr}, a density populated area in western Germany.

Vulnerable lines have significantly lower thresholds. On average, the 10 most vulnerable lines can transmit $554 \, \si{\mega\watt}$ (SD $219 \, \si{\mega\watt}$), while the grid-wide average is $1385 \, \si{\mega\watt}$ (SD $1052 \, \si{\mega\watt}$). Indeed, a change in injection has an \emph{absolute} effect on line flows; lines with low thresholds that are operating at the contingency limit (70\%) need only a small amount of additional power to overload.

There is a difference in line \emph{impedance}: $3.9 + 18.9i \, \si{\ohm}$ (SD $3.3 + 12.5i \, \si{\ohm}$) compared to the average of all lines, $2.0 + 12.0i \, \si{\ohm}$ (SD $2.6 + 13.6i \, \si{\ohm}$). This higher reactance means that vulnerable lines have higher \emph{susceptance}, making them more sensitive to changes in node voltages. Grid operators have some control over these values, and lowering the line reactance might make these lines less vulnerable. To study these questions further, we need to also take \emph{reactive power} into account, which we omitted in the DC approximation.

\begin{figure}
    \centering
    \includegraphics[width=\textwidth]{img/nomflow_stdev_trueoverloadprob_labeled.pdf}
    \caption{Visualisation of $\bm{\mu}_{\mathbf{f}}$, $\bm{\Sigma}_{\mathbf{f}}$ and $(\PROB\left[|\mel{f}_l| \geq 1 \right])_{l \in \range{m}}$ at 1 January, 11:00. The 20 most vulnerable lines are labelled.}
    \label{fig:nomflow_stdev_overload}
\end{figure}

\section{Most likely injection}
In addition to the failure probability, we compute the most likely injection to cause that failure using Theorem~\ref{thm:mostlikelyinjection}. The reader is invited to examine these injections themselves using Interactive~Figure~\ref{ifig:master}. The most likely fluctuation of three lines is given in Figure~\ref{fig:MLfluctuation1}. As expected, we find that vulnerable lines (most likely) fail due to small fluctuations in the injection, while robust lines only fail because of extreme, highly unrealistic fluctuations. 

\begin{figure}[ht]
\begin{subfigure}{\textwidth}
    \centering
    \includegraphics[width=\textwidth]{img/ML_fluctuation_with_bus_cov.pdf}
    \caption{Taking bus covariances into account.}\label{fig:MLfluctuation1}
\end{subfigure}
\begin{subfigure}{\textwidth}
    \centering
    \includegraphics[width=\textwidth]{img/ML_fluctuation_without_bus_cov.pdf}
    \caption{Using only bus variances, with no covariance.}\label{fig:MLfluctuation2}
\end{subfigure}
    \caption{The most likely fluctuation given the failure of lines 251 (1.60\% overload probability), 651 (9.56\%) and 102 ($< 10^{-15}$). By including bus covariances (top), we find the most likely fluctuation to be more spread out. Zero-sum correction (distributive slack) is not applied.}\label{fig:MLfluctuation}
\end{figure}

\subsection{Geographic distribution of fluctuations}
In general, the most likely fluctuation is not concentrated at the two endpoints of the line, but rather, it consist of small, grid-wide fluctuations. This is due to high bus covariances, but also due to power flow physics. To examine the contribution of bus covariances, we also compute the most likely injection using only the diagonal of bus variances, see Figure~\ref{fig:MLfluctuation2}. For these three lines, we find that the fluctuations are indeed more evenly distributed when bus covariances are taken in account. 

To study this hypothesis more objectively, we need a measure of how `spread out' the fluctuation is. One possibility is to use the \emph{standard deviation} of the 489 entries of a fluctuation: when a fluctuation is more evenly distributed (geographically), we expect the standard deviation of individual fluctuations to be lower. When computing these values for the 50 most vulnerable lines, we find no significant result: the average of the 50 standard deviations in fluctuations is $22.0\,\si{MW}$ (SD $6.5\,\si{MW}$) for correlated buses and $22.6\,\si{MW}$ (SD $9.5\,\si{MW}$) for uncorrelated buses. Taking a lower number of lines does not improve the result. Curiously, when \emph{all} lines are considered (including the 584 lines with negligible overload probability\footnote{\ie less than $10^{-15}$, the numerical margin of error in our case}), the average standard deviation is actually \emph{higher} with correlated buses: $1245\,\si{MW}$ (SD $9244\,\si{MW}$) versus $418\,\si{MW}$ (SD $1036\,\si{MW}$) for uncorrelated buses. However, because we are mainly interested in the most vulnerable lines, we will leave this anomaly for what it is. Regarding the first 50 lines, it seems like a different approach is needed, and we are unable to confirm our hypothesis.

\subsection{Bus extensions}
Since we did not incorporate the \emph{installed stochastic capacity} in our model, it is possible that the predicted most likely injection dictates that some buses are generating more stochastic power than what is installed. To evaluate this problem, we retrieve the total amount of installed stochastic capacity for each bus from our dataset (taking the sum of solar and wind). For a given point in time, the generation values then tell us how much a bus can fluctuate upwards (more generation) and downwards. 

Given a most likely injection, we can compute whether the fluctuation at each bus is within the possible bounds, and if not, by how much the bounds must be extended for the most likely injection to be possible. In Table~\ref{tab:results}, the number of buses that needs to be extended is given, along with the total amount of extended capacity. For simplicity, we make no distinction between an extension upwards or downwards. An extension upwards means that more solar panels or wind turbines would be needed for the injection to be possible.\footnote{This implies an inaccuracy in our dataset.} An extension downwards is harder to justify, but one could say that it means that the amount of stochastic generation \emph{before} the fluctuation must have been higher, replacing non-stochastic generation at that node.

For the most vulnerable lines, we find that the \emph{number} of extended buses can be quite high, but the total amount of addition capacity is low, in general. For reference, buses in the network have an average installed capacity of $76\,\si{\mega\watt}$ (solar); $82\,\si{\mega\watt}$ (wind). 
%
%\towrite{twee problemen: geen distr. slack meegenomen, geen onderscheid meer tussen zon en wind}
%
%\towrite{het geeft vooral een mankement van het model aan: de grenzen zouden meegenomen moeten worden in de most likely injection}

\subsection{Cascades}
Using the most likely injection, we simulate the resulting cascade. The results for all lines are given in Interactive~Figure~\ref{ifig:master}. The number of lines that either failed jointly with the initial failure, or failed during the subsequent cascade, is also given in Table~\ref{tab:results}. This extends the result of \cite{Nesti2018supplemental}, which only provides the failure probability. We find that among the 10 most vulnerable lines (at 11:00),
only the failures of lines 298, 25 and 645 result in a power island. We will discuss these lines in more detail in Section~\ref{sec:evolution}, but for now, we note that these failures quickly result a power island. (For 298 and 645, this happens the first stage.) At this point, our model becomes unreliable (see Section~\ref{sec:discussioncasc}).

\begin{figure}[ht]
\renewcommand\figurename{Interactive Figure}
\begin{subfigure}{\textwidth}
    \centering
    \includegraphics[width=\textwidth]{img/master_with_cov_251.pdf}
    \caption{Assumed failure of line 251.}\label{ifig:master251}
\end{subfigure}
%
\begin{subfigure}{\textwidth}
    \centering
    \includegraphics[width=\textwidth]{img/master_with_cov_197.pdf}
    \caption{Assumed failure of line 197.}\label{ifig:master197}
\end{subfigure}
%
    \caption{Simulated cascade stages after one assumed emergent failure. Node sizes represent the most likely injection. Long cascade sequences are truncated.
\vspace{.5em}
\newline
\emph{This figure is \textbf{interactive}: to view animated cascade simulations for all lines of the network, visit \href{https://fonsp.com/grid}{\texttt{fonsp.com/grid}}.}
}\label{ifig:master}
\end{figure}
\begin{figure}[ht]
\renewcommand\figurename{Interactive Figure}
\ContinuedFloat
\begin{subfigure}{\textwidth}
    \centering
    \includegraphics[width=\textwidth]{img/master_with_cov_182.pdf}
    \caption{Assumed failure of line 182.}\label{ifig:master182}
\end{subfigure}
%
    \caption{(continued).}\label{ifig:mastercont}
\end{figure}

\subsection{Evolution of line vulnerabilities}\label{sec:evolution}
Of course, the method above can be applied to any nominal injection, not just the injection at 1 January, 11:00. By applying the method to every hour of the first day, we find 24 different rankings, one of which is given in Table~\ref{tab:results}. This allows us to not only identify lines that are vulnerable at a given point in time, but to find lines that are a \emph{consistent vulnerability}, based on the general use of the transmission network.

Instead of providing 23 additional tables, we have summarised the results of a full day in Figure~\ref{fig:evolution_vulnerabilities}. Here, we see that some lines (like 337) are only vulnerable at one point during the day, while others (298 and 54) have a consistently high overload probability. There is a clear distinction between daytime and night-time, since the time of day determines which covariance matrix is used in the calculation. In fact, this highlights how a change in covariance influences results: some lines are only vulnerable because of the covariances brought upon by solar generation, while others are relatively unaffected.

A most striking result is that the overload probabilities of 25 and 298 are perfectly \emph{constant} for sustained periods, and both are likely to cause a cascade, resulting in an average of 108 and 76 failures, respectively. When examining these two lines in more detail, we find that both are \emph{branches out of the network towards coastal cities of the North Sea}, with high-capacity offshore wind generation. These generators were operating at full capacity during the studied day,\footnote{according to our dataset} which would cause a constant\footnote{except for the local energy usage, which is relatively small} power injection. Because the lines are \emph{branches} out of the larger graph, the flow through the line is exactly equal to the power injection at its end, and therefore constant.

Regarding the subsequent cascades of these two lines, it seems like our model falls short of giving an accurate redistribution of flow, due to the singularity caused by their removal. (No flow redistribution exists that would not change the injection.) 

\begin{figure}[ht]
\begin{subfigure}{\textwidth}
    \centering
    \includegraphics[width=\textwidth]{img/evolution_overload_probs_3.pdf}
    \caption{All lines that are, at any time during the day, among the 3 most vulnerable lines.}\label{fig:evolution_vulnerabilities_3}
\end{subfigure}
\begin{subfigure}{\textwidth}
    \centering
    \includegraphics[width=\textwidth]{img/evolution_overload_probs_3_20.pdf}
    \caption{All lines that are, at any time during the day, among the 20 most vulnerable lines.}\label{fig:evolution_vulnerabilities_3_20}
\end{subfigure}
    \caption{\label{fig:evolution_vulnerabilities}Evolution of absolute failure probabilities during 1 January 2011. Dot sizes represent final number of lost lines after the most probable cascade.}
\end{figure}

\begin{figure}[ht]
    \centering
    \includegraphics[width=\textwidth]{img/evolution_overload_probs_3_20_IID.pdf}
    \caption{For reference, the same as Figure~\ref{fig:evolution_vulnerabilities_3_20}, but computed using \emph{uncorrelated} injections.}\label{fig:evolution_vulnerabilities_3_20_IID}
\end{figure}
%
%\begin{table}
%\input{tables/top20lines.tex}
%\caption{TODO}
%\label{tab:top20old}
%\end{table}

\begin{table}
\vspace{-1.5cm}
\centerline{
\input{tables/results.tex}
}
\vspace{1cm}
\caption{The 30 most vulnerable lines at 1 January, 11:00. For each line, we have the absolute overload probability and the mean and standard deviation of line saturation. For the most likely injection, the total change (fluctuation) in injection is given, and the number of buses for which renewable generation would need to be extended for the most likely injection to be possible. \protect\newline
The number of failed lines in each cascade stage is shown. Stages in parentheses correspond to a disconnected network. (The first number is greater than $1$ when there are \emph{joint failures}.) The final column states whether the last cascade stage is disconnected (\ie whether a power island emerged).
}
\label{tab:results}
\end{table}

\section{Discussion}
\subsection{Cascading failures}\label{sec:discussioncasc}
Following \cite{Nesti2018emergentfailures}, we identify the lines most vulnerable to emergent failures, and we give the absolute overload probabilities (first two columns of Table~\ref{tab:results}). We extend the original result by also stating the (most likely) total fluctuation and the sequence of cascades. Additionally, we asses the final stage of the cascade (\ie the \emph{severity} of the emergent failure) using the final number of failed lines, and we determine whether a power island emerged in the process. These results are given in the table.

This allows us to make the important observation that most vulnerable lines do \emph{not} result in a severe cascade of failures. This means that the network will remain operational after the emergent failure, and once the nefarious fluctuation has passed, the failed line can be operational again. For some vulnerable lines, our model does predict a significant amount of cascaded failures. However, when looking at these cases individually, we find that they are all lines that branch out of the network, quickly resulting in a power island. After the power island occurred, the simulated cascades are likely erroneous. We suspect that the emergent failure of these lines will indeed cause a power island to form, but that the remainder of the network will remain operational.

\subsection{Power islands}\label{sec:discussionpowerislands}
The Optimised method computes redistributed flows efficiently, and its derivation (Section \ref{sec:optimisedmethod}) provides us with a more intuitive understanding of flow redistribution. Examining results for individual lines (\eg see Interactive Figure \ref{ifig:master}) shows realistic results. Yet, as the analyses of lines 25 and 298 demonstrate, the method is likely erroneous when the network becomes \emph{disconnected} after the line removal(s), \ie when a power island occurs.

In fact, in its original form \citep{Ronellenfitsch2017}, the optimised method is only defined when the network remains connected.
While this is a limitation of the Optimised method, it is, more generally, a limitation of using DC approximated power flow. In this approximation, we assume the network to be in a \emph{state of equilibrium}: generation matches load exactly. 

In our case, the use of a stochastic injection means that we generally do not have a zero-sum injection, contracting the assumption. This contradiction is usually justified using the concept of (distributive) slack: an overall increase or decrease in generation will occur (to compensate for the non-zero net injection), without changing the line flows.

Yet, when studying cascading failures, we are looking at a time frame much shorter than the time it takes to reach equilibrium. 
This shorter time scale generally requires an analysis of an entirely different nature: this is the study of \emph{transient stability}, which is far beyond the scope of this thesis. 

Overall, a better understanding of the physics that underlie line failures is required to study cascading failures, especially in cases where power islanding occurs. 

\subsection{Previous work \citep{Nesti2018emergentfailures}}\label{sec:discussionnesti}
This thesis was inspired by the model and case study of \cite{Nesti2018emergentfailures}. While many of the future research topics proposed by this article remain open, we have been able to independently verify their results. While our model is based on the original, there are some fundamental differences between the two. Therefore, the differences in our results provide valuable insight into the accuracy of either model. 

There are two important modifications that we chose to make to the original model. First of all, our model does not use ARMA forecasting, but a much simpler \emph{persistent forecast} as placeholder. For wind generation series, the resulting covariance matrices turn out to be very similar. We cannot comment on the similarity in solar covariances, as we were unable to reproduce these results.

A second difference is the use of a different method for computing the redistributed flow, which is based on \cite{Ronellenfitsch2017}. There is no clear practical benefit to using the Optimised method, except for computational cost. Still, our use of this method has led to the insight that a DC approximated model is not well-suited for disconnected networks, when a large power imbalance exists among connected islands. 
%Although these problems can be justified using the notion of \emph{distributive slack} TODO

This Optimised method requires the network to be a \emph{digraph}, which does not allow for parallel lines to exist. For this reason, we have combined parallel lines in our network, taking their physical properties into account. Strangely, this increases the discrepancy between the line flows computed by the LPF, and those given by the OPF algorithm. This effect could be investigated further by studying smaller test networks.


\subsubsection{Evaluation of results}
We performed a careful analysis of the results that follow from the SciGRID application, identifying new problems in the model of \cite{Nesti2018emergentfailures}. For example, we find that for almost all lines, the most likely power injection requires an extension of stochastic capacity at multiple buses. For some lines, this extension is relatively small, and it does not invalidate the result. For other lines, a significant extension is needed. We suspect that the required extensions will be much greater when analysing a point in time when renewable generation is already high. A better understanding of the origin of our dataset is needed to evaluate the significance of this problem.

This problem could be addressed \emph{within the framework of our model} by imposing additional conditions on the most likely injection. In its current form, the problem of finding the most likely injection is an optimisation problem with \emph{linear boundary conditions} (as given in the proof of Theorem~\ref{thm:mostlikelyinjection}). Because the boundary conditions can be written as a \emph{half-plane in $\mathbb{R}^n$}, we were able to derive a closed form solution. We could include the upper and lower limits of stochastic generation as addition linear conditions, which will likely make a closed-form solution unobtainable. Instead, non-linear optimisation methods could be used to find the most likely injection, given these additional conditions.\footnote{In fact, if we use this more general method to find the most likely injection, we could enforce the power injection to have zero sum by imposing one additional linear condition: $\sigma (\mat{p}) = 0$. Although this would solve the problem of having a most likely injection with non-zero sum, there is no physical argument for this imposing this condition.} See \cite{Chertkov2011} for a study using this approach.

\subsection{Future}
There are many aspects of this analysis that could be studied in more detail; some are mentioned throughout this chapter. Regarding our case study, the first shortcoming that could be addressed is the fact that we have only thoroughly looked at data of January 1$^{st}$. Like \cite{Nesti2018emergentfailures}, most of our results are computed for the nominal injection at 11:00. Additionally, we have computed our main result for the remaining 23 hours of the day, which includes hours where the \emph{night} covariance matrix is used (see Figure~\ref{fig:evolution_vulnerabilities}). 
While we can directly compute results for the remaining days of January and the remaining months of 2011, we have not yet analysed these results.

While our dataset provides an interesting case study, it does have some limitations. First of all, the dataset does not consist of physical measurements: it is constructed by combining various data sources, most of which are in turn the obtained from modelling. Because of the numerous steps needed to construct our final dataset, it is hard to quantify the inaccuracy of our results. 

Crucially, our dataset does not allow us to \emph{verify our results}, since it is \emph{too coarse} to contain fluctuations, and it provides no historical data on line failures. High-resolution stochastic generation datasets do exist, possibly for all nodes of a realistic transmission network. However, to the best of our knowledge, no dataset exist that contains continuous measurements of line currents and overloads. 

Many smaller datasets exists that can be analysed using our methods. Most notably, the \emph{IEEE test networks} can be extended with fictional stochastic generation, as demonstrated by \cite{Nesti2018emergentfailures} and \cite{Chertkov2011}. These smaller networks would allow us to more easily inspect the behaviour of individual lines in the network. Another way to construct a smaller network could be to take a \emph{subsection} of the SciGRID network.

%\towrite{
%
%Verschillen:
%- economie
%
%
%Kritiek op nesti:
%
%- ze nemen een contingency factor van 0.7 bij de OPF (arbitrair) maar voor de analyse van cascades niet. (toch?)
%
%- non-zero injection problem
%
%
%Of course, this has the same shortcoming as the model used by \cite{Nesti2018emergentfailures} (it ), but it 
%
%Although these ARMA models are fairly involved, they do not actually provide an accurate forecast.TODOfootnote{\cite{Nesti2018emergentfailures} also express this fact in their article, and note that it is only the forecast \emph{error} that is relevant in our analysis.} Using ARMA models seems unnecessarily complicated
%}
%
%

\clearpage
\end{document}"

# ⋐⋑ Cell order:
# ○ c4a8badc-6711-11ea-2456-1d08737fa0c4
# ○ 719311ac-6712-11ea-26f0-23e6e4c4af6d
