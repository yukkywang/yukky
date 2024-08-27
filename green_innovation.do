import excel using "/Users/yukkyw/Desktop/研究生毕业论文/data/merged_data.xlsx", firstrow clear
destring id, replace
destring year, replace
save "/Users/yukkyw/Desktop/研究生毕业论文/data/totaldata.dta", replace
clear
use "/Users/yukkyw/Desktop/paper/all data/控制变量/original_data_backup.dta", clear
keep id year HHI_A HHI_B HHI_C HHI_D FC_index KZ_index SA_index WW_index green_patent1 green_patent2 green_patent3 green_patent4 green_patent5 green_patent6 F010101A F010201A F100101B F100102B F100103C F100801A F100802A F100901A F100902A F100903A F100904A F101001A F101002A T60800_4 T60400_4 BoardScale_57 SupBoardScale_57 Patents1 Patents2 Patents3 TA TD mbratio lnSale Hdirrt_4
destring id, replace
destring year, replace
duplicates report id year
duplicates drop id year, force
save "/Users/yukkyw/Desktop/研究生毕业论文/data/ControlVar.dta", replace
use "/Users/yukkyw/Desktop/研究生毕业论文/data/totaldata.dta", clear

tostring id, replace
gen str6 id_str = substr("000000" + id, -6, 6)
destring id, replace
destring year, replace
duplicates report id year
duplicates drop id year, force
merge 1:1 id year using "/Users/yukkyw/Desktop/研究生毕业论文/data/ControlVar"
save "/Users/yukkyw/Desktop/研究生毕业论文/data/totaldata.dta", replace
use "/Users/yukkyw/Desktop/研究生毕业论文/data/totaldata.dta", clear
capture drop _merge
merge 1:1 id year using "/Users/yukkyw/Desktop/研究生毕业论文/data/1985～2022年各上市公司各种绿色专利数量及绿色专利知识宽度（绿色专利使用主分类号筛选）.dta"
save "/Users/yukkyw/Desktop/研究生毕业论文/data/totaldata.dta", replace
use "/Users/yukkyw/Desktop/研究生毕业论文/data/totaldata.dta", clear
capture drop _merge
merge 1:1 id year using "/Users/yukkyw/Desktop/研究生毕业论文/data/1985～2022年各上市公司各种绿色专利数量及绿色专利知识宽度（绿色专利使用分类号筛选）.dta", keepusing(method2 method2mean method2median)
save "/Users/yukkyw/Desktop/研究生毕业论文/data/totaldata.dta", replace

cd "/Users/yukkyw/Desktop/paper/peer ESG and green patent quality&efficiency/data"
use "/Users/yukkyw/Desktop/paper/peer ESG and green patent quality&efficiency/data/totaldata.dta"
destring id, replace
xtset id year
encode industry, gen(industry_code)
encode province, gen(province_code)
xi i.industry_code i.year
bysort industry_code year: egen total_b = total(Bloomberg)
bysort industry_code year: gen count = _N
bysort industry_code year: gen mean_b = total_b / count
gen leave_one_out_meanb = (total_b - Bloomberg) / (count - 1)
drop total_b count mean_b
rename leave_one_out_meanb disclosure

winsor lnage, generate(correctedage_winsor) p(0.01)
winsor leverage, generate(correctedLEV_winsor) p(0.01)
winsor roa, generate(correctedroa_winsor) p(0.01)
winsor Dturnover, generate(correctedDturn_winsor) p(0.01)
winsor size, generate(correctedsize_winsor) p(0.01)
winsor TobinQ, generate(correctedTQ_winsor) p(0.01)
winsor IndependentProportion, generate(correctedIDP_winsor) p(0.01)
winsor Envregulation, generate(correctedEnvregulation_winsor) p(0.01)
winsor lngdpc, generate(correctedlngdpc_winsor) p(0.01)
winsor lnGDP, generate(correctedlnGDP_winsor) p(0.01)
winsor BoardScale_57, generate(correctedbs_winsor) p(0.01)

rename correctedage_winsor AGE
rename correctedLEV_winsor LEV
rename correctedroa_winsor ROA
rename correctedDturn_winsor Dturn
rename correctedsize_winsor SIZE
rename correctedTQ_winsor TQ
rename correctedIDP_winsor Independent
rename correctedEnvregulation_winsor ER
rename correctedlngdpc_winsor GDP
rename correctedlnGDP_winsor gdp
rename correctedbs_winsor boardscale

bysort id (year) : drop if missing(disclosure)

winsor Trans, generate(correctedTrans_winsor) p(0.01)
rename correctedTrans_winsor efficiency

ipolate Dturn efficiency, gen(dturn_interp)
rename dturn_interp turnover
ipolate method2mean disclosure, gen(method2mean_interp)
rename method2mean_interp quality

summarize quality efficiency disclosure AGE SIZE LEV ROA turnover TQ Independent gdp SOE
centile quality efficiency disclosure AGE SIZE LEV ROA turnover TQ Independent gdp SOE, centile(50)
format quality efficiency disclosure AGE SIZE LEV ROA turnover TQ Independent gdp SOE %9.3f
pwcorr2 quality disclosure AGE SIZE LEV ROA turnover TQ Independent gdp SOE, sig
regress quality disclosure AGE SIZE LEV ROA turnover TQ Independent gdp SOE
estat vif

//baselinereg//
global cov1 AGE SIZE LEV ROA turnover TQ
global cov2 AGE SIZE LEV ROA turnover TQ Independent gdp SOE

reghdfe quality disclosure $cov1, absorb(year province_code) cluster(id)
outreg2 using baselinereg1.doc, replace word dec(3)
reghdfe efficiency disclosure $cov1, absorb(year province_code) cluster(id)
outreg2 using baselinereg2.doc, replace word dec(3)
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
outreg2 using baselinereg3.doc, replace word dec(3)
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
outreg2 using baselinereg4.doc, replace word dec(3)

//heterogeneity gdp//
centile gdp, centile(50)
scalar gdp50 = r(c_1)
gen gdp_high_low50 = (gdp > gdp50)
label define high_low50gdp 0 "Low" 1 "High"
label values gdp_high_low50 high_low50gdp
xtset id year
preserve
keep if gdp_high_low50 == 1
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store Highgdp1
outreg2 using hetero1.doc, replace word dec(3)
xtset id year
preserve
keep if gdp_high_low50 == 0
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store Lowgdp1
outreg2 using hetero2.doc, replace word dec(3)
esttab Highgdp1 Lowgdp1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe quality disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(gdp_high_low50) model(`m') reps(1000) bs first detail

xtset id year
preserve
keep if gdp_high_low50 == 1
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store Highgdp2
outreg2 using hetero3.doc, replace word dec(3)
xtset id year
preserve
keep if gdp_high_low50 == 0
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store Lowgdp2
outreg2 using hetero4.doc, replace word dec(3)
esttab Highgdp2 Lowgdp2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe efficiency disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(gdp_high_low50) model(`m') reps(1000) bs first detail

//heterogeneity ER//
centile ER, centile(50)
scalar ER50 = r(c_1)
gen ER_high_low50 = (ER > ER50)
label define high_low50ER 0 "Low" 1 "High"
label values ER_high_low50 high_low50ER
xtset id year
preserve
keep if ER_high_low50 == 1
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store HighER1
outreg2 using hetero1.doc, replace word dec(3)
xtset id year
preserve
keep if ER_high_low50 == 0
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store LowER1
outreg2 using hetero2.doc, replace word dec(3)
esttab HighER1 LowER1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe quality disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(ER_high_low50) model(`m') reps(1000) bs first detail

xtset id year
preserve
keep if ER_high_low50 == 1
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store HighER2
outreg2 using hetero3.doc, replace word dec(3)
xtset id year
preserve
keep if ER_high_low50 == 0
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store LowER2
outreg2 using hetero4.doc, replace word dec(3)
esttab HighER2 LowER2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe efficiency disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(ER_high_low50) model(`m') reps(1000) bs first detail

//heterogeneity level//
xtset id year
preserve
keep if level == 1
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store level2
outreg2 using hetero3.doc, replace word dec(3)
xtset id year
preserve
keep if level == 0
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store nonlevel2
outreg2 using hetero4.doc, replace word dec(3)
esttab level2 nonlevel2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe efficiency disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(level) model(`m') reps(1000) bs first detail

//heterogeneity Pollute//
xtset id year
preserve
keep if Pollute_1 == 1
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store Pollutehigh1
outreg2 using hetero1.doc, replace word dec(3)
xtset id year
preserve
keep if Pollute_1 == 0
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store Pollutelow1
outreg2 using hetero2.doc, replace word dec(3)
esttab Pollutehigh1 Pollutelow1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe quality disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(Pollute_1) model(`m') reps(1000) bs first detail

xtset id year
preserve
keep if Pollute_1 == 1
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store Pollutehigh2
outreg2 using hetero3.doc, replace word dec(3)
xtset id year
preserve
keep if Pollute_1 == 0
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store Pollutelow2
outreg2 using hetero4.doc, replace word dec(3)
esttab Pollutehigh2 Pollutelow2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe efficiency disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(Pollute_1) model(`m') reps(1000) bs first detail

//Robustness tests L.x//
sort id year
gen disclosure_lag = L.disclosure
reghdfe quality disclosure_lag $cov2, absorb(year province_code) cluster(id)
outreg2 using rubust1.doc, replace word dec(3)
reghdfe efficiency disclosure_lag $cov2, absorb(year province_code) cluster(id)
outreg2 using robust2.doc, replace word dec(3)

//Robustness tests FE//
reghdfe quality disclosure $cov2, absorb(province_code id)
outreg2 using rubust3.doc, replace word dec(3)
reghdfe efficiency disclosure $cov2, absorb(province_code id)
outreg2 using robust4.doc, replace word dec(3)

//Robustness tests measurement//
xi i.province_code i.year
bysort province_code year: egen total_s1 = total(Sino)
bysort province_code year: gen count = _N
bysort province_code year: gen mean_s1 = total_s1 / count
gen leave_one_out_means1 = (total_s1 - Sino) / (count - 1)
drop total_s1 count mean_s1
rename leave_one_out_means1 performance1

reghdfe quality performance1 $cov2, absorb(year province_code) cluster(id)
outreg2 using rubust5.doc, replace word dec(3)
reghdfe efficiency Sino $cov2, absorb(year province_code) cluster(id)
outreg2 using robust6.doc, replace word dec(3)

//mechanism//
centile HHI_A, centile(50)
scalar HHIA50 = r(c_1)
gen HHIA_high_low50 = (HHI_A > HHIA50)
label define high_low50HHIA 0 "Low" 1 "High"
label values HHIA_high_low50 high_low50HHIA
xtset id year
preserve
keep if HHIA_high_low50 == 1
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store HighHHIA
outreg2 using mechanism3.doc, replace word dec(3)
xtset id year
preserve
keep if HHIA_high_low50 == 0
reghdfe efficiency disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store LowHHIA
outreg2 using mechanism4.doc, replace word dec(3)
esttab HighHHIA LowHHIA, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe efficiency disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(HHIA_high_low50) model(`m') reps(1000) bs first detail

xi i.industry_code i.year
bysort industry_code year: egen total_patent3 = total(green_patent3)
bysort industry_code year: gen count = _N
bysort industry_code year: gen mean_patent3 = total_patent3 / count
gen leave_one_out_meanpatent3 = (total_patent3 - green_patent3) / (count - 1)
drop total_patent3 count mean_patent3
rename leave_one_out_meanpatent3 peerpatent3

centile KZ_index, centile(50)
scalar KZ50 = r(c_1)
gen KZ_high_low50 = (KZ_index > KZ50)
label define high_low50KZ 0 "Low" 1 "High"
label values KZ_high_low50 high_low50KZ
xtset id year
preserve
keep if KZ_high_low50 == 1
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store HighKZ
outreg2 using mechanism1.doc, replace word dec(3)
xtset id year
preserve
keep if KZ_high_low50 == 0
reghdfe quality disclosure $cov2, absorb(year province_code) cluster(id)
restore
estimates store LowKZ
outreg2 using mechanism2.doc, replace word dec(3)
esttab HighKZ LowKZ, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

local m "reghdfe quality disclosure $cov2, absorb(year province_code) vce(cluster id)" 
bdiff, group(KZ_high_low50) model(`m') reps(1000) bs first detail

//IV//
gen disclosure_lagged = L2.disclosure
ivreg2 quality (disclosure = disclosure_lag) $cov2 i.province_code* i.year*, robust first
outreg2 using IV1.doc, replace word dec(3)
ivreg2 efficiency (disclosure = disclosure_lag) $cov2 i.province_code* i.year*, robust first
outreg2 using IV2.doc, replace word dec(3)
ivreg2 quality (disclosure = disclosure_lagged) $cov2 i.province_code* i.year*, robust first
outreg2 using IV3.doc, replace word dec(3)
ivreg2 efficiency (disclosure = disclosure_lagged) $cov2 i.province_code* i.year*, robust first
outreg2 using IV4.doc, replace word dec(3)
