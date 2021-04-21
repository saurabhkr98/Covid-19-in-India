# Installation

This SISD library can be intatalled using the following command: <br>
*library(devtools)* <br>
*install_github("abh2k/sisd")*<br> <br>
This library can be imported using: <br>
*library(SISD)*<br><br>

### Authors
Abhinav Anand, Saurabh Kumar, and Palash Ghosh
<br><br>
### Parameters
The function can be called as: <br>
*sisd_cummulative(N, gamma, T_Current, T_Validation, T_Limit, T_Pred, Data, mu)* 
<br><br>

Parameters of the *sisd_cummulative* function:
<ul>
<li>N : The total population number</li>
<li>gamma : The recovery rate</li>
<li>T_Current : Denotes the day when the training phase ends. After this day, the prediction phase starts.</li>
<li>T_Validation : Length of Validation Period</li>
<li>T_Limit : Denotes the upper limit of the number of additional days that can be added to the minimum training phase to optimally choose the training phase.</li>
<li>T_Pred : Denotes the length of the prediction phase (in days).</li> 
<li>Data : The dataframe containing the observed data in the format specified below.</li>
<li>mu (Optional) : If mu is given the the death rate is fixed. If this is None, then an optimal mu is choosen using the data-driven algorithm</li> 
</ul>
<br><br>

### Flow Chart of the above time periods:<br>

![alt text](https://github.com/abh2k/sisd/blob/main/Flow_Chart.png?raw=true)

### Data format of *Data* parameter:<br>

The data should be a dataframe with three columns -> *Status*, *Date*, *Count*. <br>
<ul>
  <li>Status : Can contain three values -> <b>Confirmed, Recovered, Deceased</b></li>  
  <li>Date : The date in the <b>DD-MonthName-YYYY</b> format. For example: <b>14th March 2021</b> in this format will be <b>14-Mar-2021</b>.
  <li>Count : The number of the specified case.
</ul>
<br>
Example:<br>

![alt text](https://github.com/abh2k/sisd/blob/main/Data.png?raw=true)

### WorkFlow:
The code will calculate the cumulative number of cases on the dates with the *Data*. The it will use the data-driven algorithm to estimate *beta* and *mu*, and will generate a dataframe with the predictions.

###  Example Run:
An example run of this library is available at *sample_code.R* file in this repository.
The data we will use is available at [State Wise Daily India Dataset](https://api.covid19india.org/csv/latest/state_wise_daily.csv).
