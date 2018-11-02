use "/Users/mengjiexu/bubble/mondata.dta"
g trdmntcode=monthly(trdmnt,"YM")
format trdmntcode %tm

*- 计算行业月流通市值加权收益率
bys trdmnt nnindcd:egen sxq=sum(mretwd*msmvosd)
bys trdmnt nnindcd:egen totalvosd=sum(msmvosd)
bys trdmnt nnindcd:gen wr=sxq/totalvosd
drop sxq totalvosd
keep trdmnt year wr nnindcd nindnme trdmntcode
duplicates drop nnindcd trdmnt,force


sort nnindcd trdmnt
by nnindcd:g l=_n
g t=ln(wr+1)
*- 计算滚动buy and hold收益率
rangestat (count) t (sum) t (obs) t, by(nnindcd) interval(l 1 24)
g R = exp(t)-1
*- 计算累计收益率
rangestat (sum) wr, by(nnindcd) interval(l 1 24)
drop if wr_sum==.

*- 识别bubble
preserve
keep if wr_sum>=2.7 
sort nnindcd l
*- 去除交叠的bubble
by nnindcd:drop if trdmntcode[_n+1]<trdmntcode[_n]+24 
*- 标记bubble
g flag=1
sort nnindcd trdmntcode
save "/Users/mengjiexu/bubble/bubbleexist.dta"

restore
sort nnindcd trdmntcode
merge nnindcd trdmntcode using bubbleexist
drop _merge

*- 保留标记bubble发生后的月数据
sort nnindcd trdmntcode
by nnindcd: g rank=_n
by nnindcd: g bench=rank if flag==1
replace bench=0 if bench==.
by nnindcd: egen rbench=sum(bench)
drop bench
g gap=rank-rbench
keep if gap>=0 
keep if rbench!=0

*-画图
encode(nnindcd),g(nnindcdcode)
xtset nnindcdcode trdmntcode 
xtline wr_sum  
xtline R













