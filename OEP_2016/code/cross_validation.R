##### Cross-validation ####
# Checking in-sample fit
# Generating out-of-sample predictions
# This version:  26-11-2015
# First version: 07-01-2015
rm(list=ls(all=TRUE)) 
setwd("[DIR]/Publications/OEP_2016") 
options(scipen=4)                 

source("code/functions.R") 
source("code/clean.R")
load("tidy_data/ous.Rdata")

#### Model estimation ####
nb0<-glm.nb(outcome~index.a+violence.cl+gdp.ppp.gl+regime.l+pop.l+
             factor(iso3c)+factor(year),main) # Negative binomial (main)
p0<-glm(outcome~index.a+violence.cl+gdp.ppp.gl+regime.l+pop.l+factor(iso3c)+factor(year),
        main,family="poisson") # Poisson
l0<-glm(outcome.b~index.a+violence.cl+gdp.ppp.gl+regime.l+pop.l+factor(iso3c)+factor(year),
        main,family="binomial"(link="logit")) # Logit
n0<-glm.nb(outcome~N.a+violence.cl+gdp.ppp.gl+regime.l+pop.l+
             factor(iso3c)+factor(year),spec) # Nominal prices
s0<-glm.nb(violence~violence.l+index.a+regime.l+year,simple)# Simple model
fe0<-glm.nb(outcome~index.a+violence.cl+gdp.ppp.gl+regime.l+pop.l+
             factor(iso3c),main) # Negative binomial (only country FE)
null<-glm.nb(outcome~violence.cl+gdp.ppp.gl+regime.l+pop.l+
             factor(iso3c)+factor(year),main) # Negative binomial (main)

#### IN-SAMPLE ####

#### Check change in AUC of main model ####
z.scores<-clse(nb0,1,ccode)[2:6,3]
auc0<-auc(as.numeric(nb0$model$outcome>0),fitted(nb0))[1]

## Find all possible permutations model specification
expl<-c("index.a","violence.cl","gdp.ppp.gl","regime.l","pop.l")
prm<-combn(expl,length(expl)-1)
N<-length(expl)
f.auc<-c()
d.auc<-c()
var<-c()

## Estimate all models in a for loop
for(i in 1:N){
  # Model specification
  form<-paste("outcome~",paste(paste(paste(prm[,i]),collapse="+")),
              "+factor(iso3c)+factor(year)")
  var[i]<-setdiff(expl,prm[,i]);print(var[i])
  nb<-glm.nb(form,main) # Estimate model
  
  # Calculate difference in AUC
  f.auc[i]<-auc(as.numeric(nb$model$outcome>0),fitted(nb))[1]
  d.auc[i]<-auc0-f.auc[i]
}

## Combine data
z.scores<-data.frame(z.scores);z.scores$var<-row.names(z.scores)
dat<-data.frame(var=var,auc=d.auc)
dat<-merge(dat,z.scores)
dat$z<-abs(dat$z.scores)

## Plot results
par(mar=c(5,7,2,4),family="serif",pty="m")
plot(dat$z,dat$auc,type="p",pch=19,cex=2,col="gray20",
     bty="n",axes=FALSE,xlab="",ylab="")

# Regression line for best fit through origin
abline(lm(dat$auc~dat$z-1),lty=2)
text(1,.0006,labels=c("Best fit line through 0"),srt=25,pos=3,cex=1.1) 

# Labels & text
mtext("Country-clustered statistical significance (absolute z-value)",
      side=1,line=3,cex=1.5)
mtext("Change in predictive power (AUC)",side=2,line=5,cex=1.5)
x.adj<-c(.05,-.25,.05,.05,-.2)
y.adj<-c(0,-.0001,0,0,-.0001)
text(dat$z+x.adj,dat$auc+y.adj,adj=0,
     c("GDP per capita growth","Food price \n index","Population","Regime type",
       "Violence other countries"),cex=1.2)
# Axis
axis(1,tick=FALSE,cex.axis=1.5)
axis(2,tick=FALSE,cex.axis=1.5,las=1)
minimalrug(dat$z, side=1, line=0,lwd=2)
minimalrug(dat$auc, side=2, line=0,lwd=2)

#### Risk per month and country ####
dat<-data.frame(real=main$outcome, predicted=fitted(nb0),
                ccode=main$iso3c,year=main$year,fpi=main$index.a,
                date=main$date)
sum(dat$real);sum(dat$predicted)

dat.y<-aggregate(cbind(real,predicted)~year,dat,sum)
dat.c<-aggregate(cbind(real,predicted)~ccode,dat,sum)

#### Figure: In-sample cumulative predictions per year ####
par(mar=c(4.5,4.5,1,3),family="serif",pty="m")
plot(dat.y$year,dat.y$real,type="b",axes=FALSE,ylab="Number of violent events",
     xlab="",cex.lab=1.5,xlim=c(1990,2014));text(2012,dat.y[22,2]+1,"Observed")
par(new=TRUE)
plot(dat.y$year,dat.y$predicted,type="b",lty=2,pch=3,axes=FALSE,xlab="",ylab="",
     xlim=c(1990,2014));text(2012,dat.y[22,3],"Predicted")
axis(1,cex=1.5,tick=FALSE,at=seq(1990,2012,2));axis(2,cex=1.5,tick=FALSE,las=1)

#### Figure: In-sample predictions per country ####
dat<-merge(dat,country,all.x=TRUE)
bymedian<-with(dat,reorder(name,predicted,median))
par(mar=c(5,6,1,1),family="serif",pty="s",mfrow=c(1,3),las=1)

## Other plot
plot(dat.c$predicted,dat.c$real,bty="n",axes=FALSE,cex.lab=1.2,main="(a)",
     xlab="Predicted violence",ylab="Observed violence",cex=1.2,pch=19,log="xy")
# Axis
axis(1,tick=F,cex.axis=1);minimalrug(dat.c$predicted, side=1, line=0,lwd=2)
axis(2,tick=F, las=2,cex.axis=1);minimalrug(dat.c$real, side=2, line=0,lwd=2)

## Boxplot
boxplot(dat$predicted~bymedian,horizontal=TRUE,notch=TRUE,axes=FALSE,main="(b)",
        xlab="Fitted values",cex.lab=1.2)
axis(2,at=1:45,label=levels(bymedian),las=1,tick=F,mgp=c(1,0,0),cex.axis=.8) 
axis(1,cex=1.5,tick=FALSE,line=-1)

#### Figure: Fitted values vs. food price index ####
par(pty="s",las=0,family="serif",mfrow=c(1,1))
plot(dat$fpi,dat$predicted,col=alpha("grey",.7),axes=FALSE,cex=.7,
     xlab="Food price index (standardised)",ylab="Fitted value",cex.lab=1.2)
points(dat[dat$real>=1,]$fpi,dat[dat$real>=1,]$predicted,
       col=alpha("black",.7),pch=19,cex=.7)
axis(1,cex=1.2,tick=FALSE)
axis(2,cex=1.2,tick=FALSE,las=1)
minimalrug(dat[dat$real>=1,]$predicted, side=2, line=0,lwd=2)
minimalrug(dat[dat$real>=1,]$fpi, side=1, line=0,lwd=2)

#### OUT-OF-SAMPLE ####

## Prepare out-of-sample data
ous<-ous[ous$iso3c %in% main$iso3c,]
vars<-c("iso3c","year","date","violence","violence.l","event.cl",
         "violence.cl","index.a","N.a","gdp.ppp.gl","regime.l","pop.l","oilindex","oil.dt")
df.n<-ous[,vars]
df.n$year<-2011
df.n$incidence<-as.numeric(df.n$violence>0)
df.n$outcome<-df.n$violence
df.n[df.n$violence>=1 & df.n$violence.l>=1,]$outcome<-NA
df.n$outcome.b<-as.numeric(df.n$outcome>=1)
df.n[5:13]<-lapply(df.n[5:13],stan)

mean(df.n$outcome,na.rm=TRUE);sd(df.n$outcome,na.rm=TRUE)
mean(df.n$violence,na.rm=TRUE);sd(df.n$violence,na.rm=TRUE)

#### Generate predictions ####

## Main models
nb1<-predict(nb0,df.n,se.fit=TRUE,type="response")
p1<-predict(p0,df.n,se.fit=TRUE,type="response")
l1<-predict(l0,df.n,se.fit=TRUE,type="response")
n1<-predict(n0,df.n,se.fit=TRUE,type="response")
null1<-predict(null,df.n,se.fit=TRUE,type="response")
fe1<-predict(fe0,df.n,se.fit=TRUE,type="response")

## Alternative specifications
df.n2<-df.n
df.n2$year<-0.8264659
df.n2$outcome<-ous$violence # Using incidence
s1<-predict(s0,df.n2,se.fit=TRUE,type="response")

## Combine results
require(plyr)
obs<-ddply(df.n, .(iso3c), summarise,
           outcome=sum(outcome,na.rm=TRUE),
           violence=sum(violence),
           incidence=sum(incidence))
colnames(country)[1]<-"iso3c"
obs<-merge(obs,country)

#### Figure: Predicted values vs. food price index ####
dat<-data.frame(fpi=df.n$index.a,predicted=nb1$fit,real=df.n$violence,
                outbreak=df.n$outcome)
par(mar=c(4.5,4.5,1,1),family="serif",pty="s",mfrow=c(1,2))
# Violence
plot(dat$fpi,dat$predicted,col=alpha("grey",.7),axes=FALSE,cex=.7,main="(a)",
     xlab="Food price index (standardised)",ylab="Fitted value",cex.lab=1.5)
points(dat[dat$real>=1,]$fpi,dat[dat$real>=1,]$predicted,
       col=alpha("black",.7),pch=19,cex=.7)
axis(1,cex=1.5,tick=FALSE)
axis(2,cex=1.5,tick=FALSE,las=1)
minimalrug(dat[dat$real>=1,]$predicted, side=2, line=0,lwd=2)
minimalrug(dat[dat$real>=1,]$fpi, side=1, line=0,lwd=2)
# Outbreak of violence
plot(dat$fpi,dat$predicted,col=alpha("grey",.7),axes=FALSE,cex=.7,main="(b)",
     xlab="Food price index (standardised)",ylab="Fitted value",cex.lab=1.5)
points(dat[dat$outbreak>=1,]$fpi,dat[dat$outbreak>=1,]$predicted,
       col=alpha("black",.7),pch=19,cex=.7)
axis(1,cex=1.5,tick=FALSE)
axis(2,cex=1.5,tick=FALSE,las=1)
minimalrug(dat[dat$outbreak>=1,]$predicted, side=2, line=0,lwd=2)
minimalrug(dat[dat$outbreak>=1,]$fpi, side=1, line=0,lwd=2)

#### Figure: Prediction intervals ####
predPlot(nb1) # Negative binomial
predPlot(p1)  # Poisson
predPlot(n1)  # Nominal prices
predPlot(s1)  # Simple model

## Logit results 
temp<-data.frame(l1)
temp$iso3c<-df.n$iso3c
temp$upr<-temp$fit+qnorm(.975)*temp$se.fit
temp$lwr<-temp$fit-qnorm(.975)*temp$se.fit
temp<-ddply(temp,.(iso3c),summarise,
            upr=sum(upr),lwr=sum(lwr))

yhat<-merge(obs,temp)
yhat<-yhat[order(yhat$lwr,yhat$incidence),]

par(mar=c(4.5,4.5,1,3),family="serif",pty="m",mgp=c(5,1,0))
plot(yhat$incidence,1:length(yhat$incidence),type="n",xlim=c(0,max(yhat$incidence)),
     axes=FALSE,xlab="Number of months with violence",ylab="",main="",cex.lab=1.5)
segments(yhat$lwr,1:length(yhat$incidence),
          yhat$upr,lwd=10,col=alpha("grey",.3),lend=2)
points(yhat$incidence,1:length(yhat$incidence),pch=19,cex=.9)
axis(1,tick=F,cex.axis=1.5)
axis(2,at=1:45,label=yhat$name,las=1,tick=F,mgp=c(1,0,0),cex.axis=.8) 

