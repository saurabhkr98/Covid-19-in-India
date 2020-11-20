import pandas as pd
import matplotlib.pyplot as plt
import numpy as np


gamma, mu = 1./14, 0.002
cur_day = 70
last_n_day = 30
next_n_days = 20


import pandas as pd
data = pd.read_csv("state_wise_daily.csv")
delhi_data = data[{ "Status", "Date", "DL"}]
  
dt = []
c = []
r = []
d = []
for i in range(len(delhi_data)):
    num, status, date = delhi_data.iloc[i]["DL"], delhi_data.iloc[i]["Status"], delhi_data.iloc[i]["Date"]
    if date not in dt:
        dt.append(date)
    if status == "Confirmed":
        c.append(num)
    elif status == "Recovered":
        r.append(num)
    elif  status  == "Deceased":
        d.append(num)
df = pd.DataFrame()
df["Date"] = dt
df["Confirmed"] = c
df["Cured"] = r
df["Deaths"] = d




organised_data = {}

def get_Data(data, N):
    s = {}
    susceptible = [N - data.iloc[0]["Confirmed"]]
    comulative_inf = [data.iloc[0]["Confirmed"]]
    infected_active = [data.iloc[0]["Confirmed"] - data.iloc[0]["Cured"] - data.iloc[0]["Deaths"]]
    deceased = [data.iloc[0]["Deaths"]]
    date = [data.iloc[0]["Date"]]
    day = [0]

    for i in range(1, len(data)):
        
        comulative_inf.append( comulative_inf[-1] + data.iloc[i]["Confirmed"])
        infected_active.append(infected_active[-1] + data.iloc[i]["Confirmed"] - data.iloc[i]["Cured"] - data.iloc[i]["Deaths"])
        susceptible.append(N - infected_active[-1])
        date.append(data.iloc[i]["Date"])
        deceased.append(deceased[-1] + data.iloc[i]["Deaths"])
        day.append(i)

    s["infected"] = infected_active
    s["susceptible"] = susceptible
    s["comulative_inf"] = comulative_inf
    s["deceased"] = deceased
    s["date"] = date
    s["day"] = day
    return s
            
    

organised_data = get_Data(df, 18710922)

def draw(d, name):
    fig = plt.figure(facecolor='w')
    ax = fig.add_subplot(111, facecolor='#dddddd', axisbelow=True)
    t =  [i for i in range(0,       len(d)        )]
    ax.plot( t , d, 'r', alpha=0.5, lw=2, label=name)
    ax.set_xlabel('Time /days')
    ax.set_ylabel('Number')
    ax.yaxis.set_tick_params(length=0)
    ax.xaxis.set_tick_params(length=0)
    ax.grid(b=True, which='major', c='w', lw=2, ls='-')


def draw1(d, d1,  name, gamma, state):
    fig = plt.figure(facecolor='w')
    ax = fig.add_subplot(111, facecolor='#dddddd', axisbelow=True)
    t =  [i for i in range(0, len(d))]
    ax.plot( t , d, 'r', alpha=0.5, lw=2, label=(name+" observed"+ " and"+" p = "+str(gamma)[:4]))
    ax.plot( t , d1, 'b', alpha=0.5, lw=2, label=(name+"pred"))
    ax.set_xlabel('Time /days')
    ax.set_ylabel('Number')
    ax.yaxis.set_tick_params(length=0)
    ax.xaxis.set_tick_params(length=0)
    ax.set_title(("Delhi"+name+" with"+" p= "  + "1"))
    ax.grid(b=True, which='major', c='w', lw=2, ls='-')

def sisd(N, beta, gamma, mu, cur_day, last_n, data):
    start = cur_day - last_n
    assert start >= 0
    S0 = data["susceptible"][start]
    I0 = data["infected"][start]
    C0 = data["comulative_inf"][start]
    D0 = data["deceased"][start]
    S = [S0]
    I = [I0]
    C = [C0]
    D = [D0] 
    S_P, I_P, C_P, D_P = S0, I0, C0, D0
    while(start <= cur_day):
        start += 1 
        S_N = S_P - S_P*I_P*beta/N + gamma*I_P
        I_N = I_P + S_P*I_P*beta/N - gamma*I_P - mu*I_P
        C_N = C_P + S_P*I_P*beta/N
        D_N = D_P + mu*I_P
        S_P, I_P, C_P, D_P = S_N, I_N, C_N, D_N
        S.append(S_N)
        I.append(I_N)
        C.append(C_N)
        D.append(D_N)
    return S, I, C, D

def sisd_pred(N, beta, gamma, mu, cur_day, next_n_days, data):
    start = cur_day
    assert start >= 0
    S0 = data["susceptible"][start]
    I0 = data["infected"][start]
    C0 = data["comulative_inf"][start]
    D0 = data["deceased"][start]
    S = [S0]
    I = [I0]
    C = [C0]
    D = [D0]
    S_P, I_P, C_P, D_P = S0, I0, C0, D0
    while(start <= cur_day + next_n_days):
        start += 1 
        S_N = S_P - S_P*I_P*beta/N + gamma*I_P
        I_N = I_P + S_P*I_P*beta/N - gamma*I_P - mu*I_P
        C_N = C_P + S_P*I_P*beta/N
        D_N = D_P + mu*I_P
        S_P, I_P, C_P, D_P = S_N, I_N, C_N, D_N
        S.append(S_N)
        I.append(I_N)
        C.append(C_N)
        D.append(D_N)
    return S, I, C, D



b_beta1 = 0
err = -1
beta1 = 0



while(beta1<2):
    S,I,C,D = sisd(18710922, beta1, gamma, mu, cur_day, last_n_day, organised_data)
    nerr = 0
    start = cur_day - last_n_day
    idx = 0
    while(idx < len(I)): 
        nerr +=  abs((C[idx]*10 - organised_data["comulative_inf"][start]*10)/organised_data["comulative_inf"][start])**2  + abs((I[idx]*10 - organised_data["infected"][start]*10)/organised_data["infected"][start])**2 
        idx += 1
        start += 1
    if err == -1:
        err = nerr
        b_beta1 = beta1 
    if err>nerr:
        err=nerr
        b_beta1 = beta1 
    beta1+=0.01

#Train
S,I,C,D = sisd(18710922, b_beta1, gamma, mu, cur_day, last_n_day, organised_data)
draw1(organised_data["comulative_inf"][cur_day-last_n_day-1:cur_day+1], C ,  "_cumulative_", gamma, "Delhi")
draw1(organised_data["infected"][cur_day-last_n_day-1:cur_day+1], I ,  "_infected_", gamma, "Delhi") 
draw1(organised_data["deceased"][cur_day-last_n_day-1:cur_day+1], D ,  "_infected_", gamma, "Delhi") 

S_t,I_t,C_t,D_t = sisd_pred(18710922, b_beta1, gamma, mu, cur_day, next_n_days, organised_data)
draw1(organised_data["comulative_inf"][cur_day: cur_day+next_n_days+2], C_t ,  "_cumulative_", gamma, "Delhi")
draw1(organised_data["infected"][cur_day: cur_day+next_n_days+2], I_t ,  "_infected_", gamma, "Delhi")
draw1(organised_data["deceased"][cur_day: cur_day+next_n_days+2], D_t ,  "_infected_", gamma, "Delhi") 




fig = plt.figure(facecolor='w')
ax = fig.add_subplot(111, facecolor='#dddddd', axisbelow=True)
train =  [i for i in range(cur_day-last_n_day-1, cur_day+1)]
test  = [i for i in range(cur_day, cur_day+next_n_days+2)]
obs  = [i for i in range(cur_day-last_n_day-1, cur_day+next_n_days+2)]
ax.plot(obs, organised_data["comulative_inf"][cur_day-last_n_day-1: cur_day+next_n_days+2], 'black', alpha=0.5, lw=2, label=("observed"))
ax.plot(train, C, 'b', alpha=0.5, lw=2, label=("trained"))
ax.plot(test, C_t, 'g', alpha=0.5, lw=2, label=("prediction"))
ax.set_xlabel('Time /days')
ax.set_ylabel('Number')
ax.yaxis.set_tick_params(length=0)
ax.xaxis.set_tick_params(length=0)
plt.title("Cumulative cases analysis")
ax.grid(b=True, which='major', c='w', lw=2, ls='-')
leg = ax.legend();
plt.savefig('C2.png')