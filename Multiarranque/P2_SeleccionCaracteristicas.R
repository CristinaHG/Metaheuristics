#reading datasets
library(foreign)
Aritmia<- read.arff("/home/cris/mrcrstnherediagmez@gmail.com/MH/MH-FeatureSelectionProblem/arrhythmia.arff")
wdbc<- read.arff("/home/cris/mrcrstnherediagmez@gmail.com/MH/MH-FeatureSelectionProblem/wdbc.arff")
Libras<- read.arff("/home/cris/mrcrstnherediagmez@gmail.com/MH/MH-FeatureSelectionProblem/movement_libras.arff")

#-------------------------------normalizing and cleanind data--------------------------------
normalize <- function(x) { 
  x <- as.matrix(as.numeric(x))
  minAttr=apply(x, 2, min)
  maxAttr=apply(x, 2, max)
  x <- sweep(x, 2, minAttr, FUN="-") 
  x=sweep(x, 2,  maxAttr-minAttr, "/") 
  x[is.nan(x)]<- 0
  return (x)
} 

#quit class column to avoid normalizing it
nAritmia<-Aritmia[ ,-ncol(Aritmia)]
nWdbc<-wdbc[ , -1]
nLibras<-Libras[ ,-ncol(Libras)]
#normalizing
nAritmia<-apply(nAritmia,2,normalize)
nWdbc<-apply(nWdbc,2,normalize)
nLibras<-apply(nLibras,2,normalize)
#adding class column to normalized data
AritmiaNormalized<-data.frame(nAritmia,Aritmia$class)
wdbcNormalized<-data.frame(nWdbc,wdbc$class)
LibrasNormalized<-data.frame(nLibras,Libras$Class)
#deleting columns wich row's values are all the same
AritmiaNormalized=AritmiaNormalized[sapply(AritmiaNormalized, function(x) length(unique(x))>1)]
wdbcNormalized=wdbcNormalized[sapply(wdbcNormalized, function(x) length(unique(x))>1)]
LibrasNormalized=LibrasNormalized[sapply(LibrasNormalized, function(x) length(unique(x))>1)]

#naming all classes columns the same:
colnames(wdbcNormalized)[ncol(wdbcNormalized)]<-"class"
colnames(LibrasNormalized)[ncol(LibrasNormalized)]<-"class"
colnames(AritmiaNormalized)[ncol(AritmiaNormalized)]<-"class"

#function to see test-train distribution
partitionDistribution <- function(training,test) {
  print(paste('Training: ', nrow(training), 'instances'))
  print(summary(training$Aritmia.class) / nrow(training) * 100) # Porcentaje de muestras por clase
  print(paste('Test: ', nrow(test), 'instances'))
  print(summary(test$Aritmia.class)  / nrow(test) * 100)
}

# using caret
library(caret)

#function used to adjust 3nn: receive predictors as param
Adjust3nn<-function(formula,training_data){
  set.seed(12345)
  modelo<-train(formula,data=training_data,method="knn",tuneGrid=expand.grid(.k=3))
  return(modelo)
}

#function that adjust KNN with K=3 using all features as predictors 
model <- function(z,test) { 
  evalua<-0
  set.seed(12345)
  modelo<-train(class ~.,data=z,method="knn", tuneGrid=expand.grid(.k=3))
#   if(nrow(z)<nrow(test)){
#     test<-test[-nrow(test),]
    pred<-predict(modelo,test)
    post<-postResample(pred,test$class)
    evalua<-post
 # }else{
#     pred<-predict(modelo,test)
#     post<-postResample(pred,test$class)
#     evalua<-post
#   }
  return(evalua)
}


#---------------------function that returns formula using features of dataset that corresponds to selected ones in a binary vector
getFeaturesForm<-function(selected,dataset){
  names<-(colnames(dataset)) #get column names of dataset
  featuresList<-lapply(seq_along(selected), function(i) { #get list with names of features selected in bit mask
    if (selected[[i]]==1){
      names[[i]]
    }}) 
  #construct formula. Predictors are fetureList elements which are not null,separated by +
  my.formula <- paste( 'class', '~', paste(Filter(Negate(is.null), featuresList), collapse=' + ' ))
  myf<-as.formula(my.formula)#create formula and return 
  return (myf)
}


#-----------------------function that generates neightbour by fliping a given position------------------   
   flip<-function(selected,index){
     if(selected[[index]]==1){
       selected[[index]]<-0
     }else{
       selected[[index]]<-1}
     return (selected)
   }
   
#---------CV 2X5 for 3NN using all variables as predictors----------

#---------for WDBC----------
Trainvstest3nn <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(wdbcNormalized$class, p =.50, list = FALSE)
  training=wdbcNormalized[indices,]
  test=wdbcNormalized[-indices,]
  
  time<-system.time(solution<-model(training,test))
  list(solution,time)
})

TestvsTrain3nn <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(wdbcNormalized$class, p =.50, list = FALSE)
  test=wdbcNormalized[indices,]
  training=wdbcNormalized[-indices,]
  time<-system.time(solution<-model(training,test))
  list(solution,time)
})

#---------for Movement Libras----------
Trainvstest3nnML <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(LibrasNormalized$class, p =.50, list = FALSE)
  training=LibrasNormalized[indices,]
  test=LibrasNormalized[-indices,]
  
  time<-system.time(solution<-model(training,test))
  list(solution,time)
})

TestvsTrain3nnML <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(LibrasNormalized$class, p =.50, list = FALSE)
  test=LibrasNormalized[indices,]
  training=LibrasNormalized[-indices,]
  time<-system.time(solution<-model(training,test))
  list(solution,time)
})

#---------for Arritmia----------
Trainvstest3nnArr <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(AritmiaNormalized$class, p =.50, list = FALSE)
  training=AritmiaNormalized[indices,]
  test=AritmiaNormalized[-indices,]
  
  time<-system.time(solution<-model(training,test))
  list(solution,time)
})

TestvsTrain3nnArr <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(AritmiaNormalized$class, p =.50, list = FALSE)
  test=AritmiaNormalized[indices,]
  training=AritmiaNormalized[-indices,]
  time<-system.time(solution<-model(training,test))
  list(solution,time)
})



#----------------------------------------------
#       PRACTICE 2: MULTI-START METAHEURISTICS
#----------------------------------------------

#-----------------LOCAL SEARCH------------------
# it has been modified from last practice to receive a initial solution as param
LocalSearchModified<-function(training,test,sIni){
  dataset<-training
  nfeatures<-ncol(training)-1 #all except itself
  selected<-sIni #initially, selected features are the initial solution 
  AccuracyActual<-0 #best accu at moment. Initially is 0
  bestSolFound=FALSE 
  nEval<-0 #number of evaluations,should be no more of 15000. Initially 0
  vecina<-0
  AccuracyInitial<-0 #initial accuracy of the solution 
  fin<-FALSE #gets TRUE if explored all neighborhood without success
  modeloActual<-Adjust3nn(getFeaturesForm(selected,dataset),dataset)
  bestmodel<-0
  
  pred<-predict(modeloActual,test)
  post<-postResample(pred,test$class)

  AccuracyActual<-post[[1]]
  AccuracyInitial<-AccuracyActual
  #print(paste0("Accuracy  inicial de solucion:",AccuracyActual))
  
  while((!fin) && (nEval<15000)){
    
    bestSolFound=FALSE
    for( i in seq_along(selected)){
      if(!bestSolFound){
        vecina<-flip(selected,i)
        if(sum(vecina)!=0){ #comprobation because train dont let adjust a model with no features. If features selected sum 0 => acuracy=0 
          modeloActual<-Adjust3nn(getFeaturesForm(vecina,dataset),dataset)
   
          pred<-predict(modeloActual,test)
          post<-postResample(pred,test$class)
          evaluaVecina<-post[[1]]
          
          nEval<-nEval+1 #number of evaluated solutions increments
        }else{
          evaluaVecina<-0
          nEval<-nEval+1
        }
        #if new solution's accuracy is better than actual => update actual solution
        if(evaluaVecina>AccuracyActual){
          bestSolFound=TRUE
          selected<-vecina
          AccuracyActual<-evaluaVecina
          bestmodel<-modeloActual
        }
        if(i==nfeatures){
          fin<-TRUE
          break
        }
      }else{
        break
      }
      if(nEval>=15000){ 
        break
      }
    }
  }
  return (list(bestmodel,selected,AccuracyActual,AccuracyInitial))
}


#-----------------BMB------------------   
BMB<-function(training,test){
 # dataset=training
  nfeatures<-ncol(training)-1
  bestIndex<-0 #index of best model in Model's array
  BestAccuracyGlobal<-0 #Best accuraccy in global
 
  #generating 25 random solutions and optimizing each one by aplying Local Seach :done parallely
  library(parallel)
  no_cores <- detectCores()
  cl <- makeCluster(no_cores,type="FORK")
  ModelosBL <- parLapply(cl,seq_along(1:25),  function(i){
    set.seed(12345*i)
    vecina<-sample(0:1,nfeatures,replace=TRUE)
    modelo<-LocalSearchModified(training,test,vecina)
    modelo
  }) 
  stopCluster(cl)
  
  #checking which Accuracy(of all adjusted Models) is the best and saving its model's index on Model's list
  for(i in seq_along(ModelosBL)){
    if(ModelosBL[[i]][[3]][1]>BestAccuracyGlobal){
      BestAccuracyGlobal<-ModelosBL[[i]][[3]][1]
      bestIndex<-i
    }
  }
  #return the best model, which has best accuracy
  return(ModelosBL[[bestIndex]])
}


#----------------BMB executions-------------------------------------------
#----------------------------------for wdbc---------------------------------------

modelosTrainvstestBMB <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(wdbcNormalized$class, p =.50, list = FALSE)
  training=wdbcNormalized[indices,]
  test=wdbcNormalized[-indices,]
  time<-system.time(SolucionmodeloBMB<-BMB(training,test))
  list(SolucionmodeloBMB,time)
})

modelosTestvsTrainBMB <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(wdbcNormalized$class, p =.50, list = FALSE)
  test=wdbcNormalized[indices,]
  training=wdbcNormalized[-indices,]
  
  time<-system.time(SolucionmodeloBMB<-BMB(training,test))
  list(SolucionmodeloBMB,time)
})

ReductionWDBC_BMB_SinInter<-lapply(seq_along(1:5),function(i){
  100*((ncol(wdbcNormalized)-sum(modelosTrainvstestBMB[1,i][[1]][[2]]))/ncol(wdbcNormalized))
})                  

ReductionWDBC_BMB_Inter<-lapply(seq_along(1:5),function(i){
  100*((ncol(wdbcNormalized)-sum(modelosTestvsTrainBMB[1,i][[1]][[2]]))/ncol(wdbcNormalized))
})  

#----------------------------------Para Movement Libras---------------------------------------

modelosTrainvstestBMB_Libras <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(LibrasNormalized$class, p =.50, list = FALSE)
  training=LibrasNormalized[indices,]
  test=LibrasNormalized[-indices,]
  
  time<-system.time(SolucionmodeloBMB<-BMB(training,test))
  list(SolucionmodeloBMB,time)
})

modelosTestvsTrainBMB_Libras <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(LibrasNormalized$class, p =.50, list = FALSE)
  test=LibrasNormalized[indices,]
  training=LibrasNormalized[-indices,]
  
  time<-system.time(SolucionmodeloBMB<-BMB(training,test))
  list(SolucionmodeloBMB,time)
})

ReductionWDBC_BMB_SinInter_Libras<-lapply(seq_along(1:5),function(i){
  100*((ncol(LibrasNormalized)-sum(modelosTrainvstestBMB_Libras[1,i][[1]][[2]]))/ncol(LibrasNormalized))
})                  

ReductionWDBC_BMB_Inter_Libras<-lapply(seq_along(1:5),function(i){
  100*((ncol(LibrasNormalized)-sum(modelosTestvsTrainBMB_Libras[1,i][[1]][[2]]))/ncol(LibrasNormalized))
})  

#----------------------------------Para Arritmia--------------------------------------

modelosTrainvstestBMB_Arr <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(AritmiaNormalized$class, p =.50, list = FALSE)
  training=AritmiaNormalized[indices,]
  test=AritmiaNormalized[-indices,]
  
  time<-system.time(SolucionmodeloBMB<-BMB(training,test))
  list(SolucionmodeloBMB,time)
})

modelosTestvsTrainBMB_Arr <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(AritmiaNormalized$class, p =.50, list = FALSE)
  test=AritmiaNormalized[indices,]
  training=AritmiaNormalized[-indices,]
  time<-system.time(SolucionmodeloBMB<-BMB(training,test))
  list(SolucionmodeloBMB,time)
})

ReductionWDBC_BMB_SinInter_Arr<-lapply(seq_along(1:5),function(i){
  100*((ncol(AritmiaNormalized)-sum(modelosTrainvstestBMB_Arr[1,i][[1]][[2]]))/ncol(AritmiaNormalized))
})                  

ReductionWDBC_BMB_Inter_Libras<-lapply(seq_along(1:5),function(i){
  100*((ncol(AritmiaNormalized)-sum(modelosTestvsTrainBMB_Arr[1,i][[1]][[2]]))/ncol(AritmiaNormalized))
})  


#-------------------------GRASP---------------------------------

#--------------------ramdommized greedy algorithm---------------
greedyRndm <- function(training,test,seed) { 
  dataset<-training
  selected<-as.vector(rep(0,ncol(dataset)-1)) #initially no features are selected(all 0)
  selectedAndCandidate<-as.vector(rep(0,ncol(dataset)-1))#where selected+feature randomly selected is stored. initially vectorof 0
  bestAccu<-0 #initially,best accuracy is zero
  bestmodel<-0 #initially,there's no best model
  final<-FALSE #initially final is false
  LRC<-0 #List of reduced candidates. Initially empty
  cmejor<-0
  cpeor<-0
  umbral<-0
  alpha<-0.3
  ganancias<-0 #matrix where accuracy gain of each feature is stored.Initially 0
  randomIndex<-0#random index generated
  randomFeature<-0#random feature that corresponds to ramdomIndex position in LRC
  featuresList<-as.vector(seq_along(1:(ncol(dataset)-1))) #list which constains indexes that goes from 1 to dataset features
  evalua<-0#var where test accu is stored.initially 0
  
  while((sum(featuresList)!=0) && !(final)) { #while features List is not NULL and final is false
    
      ganancias<-sapply(seq_along(1:(length(featuresList))),function(i){ #compute gain of each feature 
        
        if(featuresList[i]!=0){ # featuresList[i] is set to 0 when feature is taken. So here checks is has not been taken
          sol<-as.vector(rep(0,ncol(dataset)-1))
          sol[i]<-1
          modelo=Adjust3nn(getFeaturesForm(sol,dataset),dataset) #adjust3nn with that feature
          pred<-predict(modelo,test)
          post<-postResample(pred,test$class)
          evalua<-post[[1]]#get test accuracy
            
        }else{ #else,gain associated is 0 
          evalua<-0
        }
        evalua
    })
    
    cmejor<-max(ganancias)#compute cmejor
    if (min(ganancias)==0){#compute cpeor. If some gains in ganancias vector are 0,they're ignored and next is taken
      cpeor<-min(ganancias[-which(ganancias==0.00)])
    }else{
      cpeor<-min(ganancias)
    }
    umbral<-cmejor-(alpha*(cmejor-cpeor))#compute umbral
    
    LRC<-which(ganancias >= umbral)# get reduce list of candidates:gains in ganancias wich are over the umbral
    set.seed(seed*(runif(1, min=1000, max=(78496327/seed)))+sum(LRC))#set random seed (as much random as possible) to get randomly a feature of LRC
    randomIndex<-sample(1:length(LRC),1,replace = FALSE)#take one random index in LRC
    randomFeature<-LRC[randomIndex]#get feature of LRC in that randomIndex position (it is really the index if true feature in taininng dataset)
    
    modelo<-0
    evalua<-0
        #adjust knn with K=3 using features selected actually plus the one slected randomly from LRC 
        selectedAndCandidate[[randomFeature]]<-1
        modelo=Adjust3nn(getFeaturesForm(selectedAndCandidate,dataset),dataset)#adjust model with features selected+ new feature
        pred<-predict(modelo,test)
        post<-postResample(pred,test$class) #compute test accuracy
        evalua<-post[[1]]
         
    if(evalua>bestAccu){ #if now accuracy is better that the actual best
        selected<-selectedAndCandidate
        featuresList[randomFeature]<-0#feature selected. Cannot be taken from featuresList again
        bestAccu<-evalua#update best accuracy
        bestmodel<-modelo#update bestmodel
    }else{
        final=TRUE #feature added dont improve actual sol
    }
        selectedAndCandidate<-selected  #in any case,selectedAndcandidate is selected until feature added
    }
  return (list(bestmodel,selected,bestAccu))
} 


#---------------------GRASP ALGORITHM---------------

GRASP<-function(training,test,numSol){
  BestAccuracyGlobal<-0 #is the best accracy of all solutions.initially 0
  bestIndex<-0 #this is the index of model in model's list ,which accuracy is the best
  
  library(parallel)#do pararelly:
  no_cores <- detectCores()
  cl <- makeCluster(no_cores,type="FORK")
  
  GreedySolutions<-parSapply(cl,seq_along(1:numSol),function(i){#compute as much greedysolutions as specified
    set.seed(i)
    i.seed<-(i*floor(runif(1, min=700, max=2829)))#random seed to compute random greedy sol
    solution<-greedyRndm(training,test,i.seed)#greedy solutions
    solution
})
  stopCluster(cl)#stop core cluster
  
  library(parallel)#do pararelly:
  no_cores <- detectCores()
  cl <- makeCluster(no_cores,type="FORK")
  
  ModelosBL <- parLapply(cl,seq_along(1:(ncol(GreedySolutions))),  function(i){ #apply Local Search on each Greedy solution generated above
    vecina<-GreedySolutions[2,i][[1]]#get greedy Solution
    modelo<-LocalSearchModified(training,test,vecina)#apply Local Seach to that greedy sol 
    modelo
  }) 
  stopCluster(cl)#stop cluster
  
  for(i in seq_along(ModelosBL)){ #for each solution obtained in Local Search, now take the best
    if(ModelosBL[[i]][[3]][[1]]>BestAccuracyGlobal){ #check which has best accuracy and take them
      BestAccuracyGlobal<-ModelosBL[[i]][[3]][[1]]
      bestIndex<-i #best solution index in Solution's array
    }
  }
  return(ModelosBL[[bestIndex]])
}


#----------------GRASP executions-------------------------------------------
#----------------------------------for wdbc---------------------------------------

modelosTrainvstestGRASP <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(wdbcNormalized$class, p =.50, list = FALSE)
  training=wdbcNormalized[indices,]
  test=wdbcNormalized[-indices,]
  time<-system.time(SolucionmodeloGRASP<-GRASP(training,test,25))
  list(SolucionmodeloGRASP,time)
})

modelosTestvsTrainGRASP <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(wdbcNormalized$class, p =.50, list = FALSE)
  test=wdbcNormalized[indices,]
  training=wdbcNormalized[-indices,]
  
  time<-system.time(SolucionmodeloGRASP<-GRASP(training,test,25))
  list(SolucionmodeloGRASP,time)
})

# ReductionWDBC_GRASP_SinInter<-lapply(seq_along(1:5),function(i){
#   100*((ncol(wdbcNormalized)-sum(modelosTrainvstestGRASP[1,i][[1]][[2]]))/ncol(wdbcNormalized))
# })                  

ReductionWDBC_GRASP_Inter<-lapply(seq_along(1:5),function(i){
  100*((ncol(wdbcNormalized)-sum(modelosTestvsTrainGRASP[1,i][[1]][[2]]))/ncol(wdbcNormalized))
})  

#----------------------------------Para Movement Libras---------------------------------------

modelosTrainvstestGRASP_Libras <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(LibrasNormalized$class, p =.50, list = FALSE)
  training=LibrasNormalized[indices,]
  test=LibrasNormalized[-indices,]
  
  time<-system.time(SolucionmodeloGRASP<-GRASP(training,test,25))
  list(SolucionmodeloGRASP,time)
})

modelosTestvsTrainGRASP_Libras <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(LibrasNormalized$class, p =.50, list = FALSE)
  test=LibrasNormalized[indices,]
  training=LibrasNormalized[-indices,]
  
  time<-system.time(SolucionmodeloGRASP<-GRASP(training,test,25))
  list(SolucionmodeloGRASP,time)
})

ReductionWDBC_GRASP_SinInter_Libras<-lapply(seq_along(1:5),function(i){
  100*((ncol(LibrasNormalized)-sum(modelosTrainvstestGRASP_Libras[1,i][[1]][[2]]))/ncol(LibrasNormalized))
})                  

ReductionWDBC_GRASP_Inter_Libras<-lapply(seq_along(1:5),function(i){
  100*((ncol(LibrasNormalized)-sum(modelosTestvsTrainGRASP_Libras[1,i][[1]][[2]]))/ncol(LibrasNormalized))
})  

#----------------------------------Para Arritmia--------------------------------------

modelosTrainvstestGRASP_Arr <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(AritmiaNormalized$class, p =.50, list = FALSE)
  training=AritmiaNormalized[indices,]
  test=AritmiaNormalized[-indices,]
  
  time<-system.time(SolucionmodeloGRASP<-GRASP(training,test,25))
  list(SolucionmodeloGRASP,time)
})

modelosTestvsTrainGRASP_Arr <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(AritmiaNormalized$class, p =.50, list = FALSE)
  test=AritmiaNormalized[indices,]
  training=AritmiaNormalized[-indices,]
  time<-system.time(SolucionmodeloGRASP<-GRASP(training,test,25))
  list(SolucionmodeloGRASP,time)
})

ReductionWDBC_GRASP_SinInter_Arr<-lapply(seq_along(1:5),function(i){
  100*((ncol(AritmiaNormalized)-sum(modelosTrainvstestGRASP_Arr[1,i][[1]][[2]]))/ncol(AritmiaNormalized))
})                  

ReductionWDBC_GRASP_Inter_Libras<-lapply(seq_along(1:5),function(i){
  100*((ncol(AritmiaNormalized)-sum(modelosTestvsTrainGRASP_Arr[1,i][[1]][[2]]))/ncol(AritmiaNormalized))
})  


#------------------------------ILS-----------------------------
ILS<-function(training,test,i.seed){
  set.seed(i.seed) #set seed pass as paremeter. That avoid choosing same initial solution each time
  nfeatures<-ncol(training)-1
  sIni<-sample(0:1,nfeatures,replace=TRUE) #initial solution
  sLSearch<-LocalSearchModified(training,test,sIni) #applying Local Search to initial solution
  bestAtMoment<-0
  bestAccu<-0
  iter<-1
  t<-floor(0.1*ncol(training))#10% of the features
  mutated<-0
  Accuini<-sLSearch[[4]][[1]]
  
  if(sLSearch[[3]][[1]]>bestAccu){ #update best solution at moment to apply mutation to it
    bestAtMoment<-sLSearch[[2]]
    bestAccu<-sLSearch[[3]][[1]]
  }
  
  while(iter!=25){
  
  set.seed(iter*234567)#set seed randomly 
  randomIndex<-sample(1:nfeatures,t,replace = FALSE)  #get indexes of features to be changed, randomly
  
  mutated<-bestAtMoment
  
  for(i in randomIndex){ #change elements from mutated sol
    mutated<-flip(mutated,i)
  }
  sLSearch<-LocalSearchModified(training,test,mutated)#apply LocalSearch 
  
  if(sLSearch[[3]][[1]]>bestAccu){ #update best solution at moment to apply mutation to it
    bestAtMoment<-sLSearch[[2]]
    bestAccu<-sLSearch[[3]][[1]]
  }
  iter<-iter+1#increase number of iterations
  }
  return (list(bestAtMoment, bestAccu, Accuini))
}

#----------------ILS executions-------------------------------------------
#----------------------------------for wdbc---------------------------------------

modelosTrainvstestILS <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(wdbcNormalized$class, p =.50, list = FALSE)
  training=wdbcNormalized[indices,]
  test=wdbcNormalized[-indices,]
  time<-system.time(SolucionmodeloILS<-ILS(training,test,i*234567))
  list(SolucionmodeloILS,time)
})


modelosTestvsTrainILS <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(wdbcNormalized$class, p =.50, list = FALSE)
  test=wdbcNormalized[indices,]
  training=wdbcNormalized[-indices,]
  
  time<-system.time(SolucionmodeloILS<-ILS(training,test,i*234567))
  list(SolucionmodeloILS,time)
})

ReductionWDBC_ILS_SinInter<-lapply(seq_along(1:5),function(i){
  100*((ncol(wdbcNormalized)-sum(modelosTrainvstestILS[1,i][[1]][[2]]))/ncol(wdbcNormalized))
})                  

ReductionWDBC_ILS_Inter<-lapply(seq_along(1:5),function(i){
  100*((ncol(wdbcNormalized)-sum(modelosTestvsTrainILS[1,i][[1]][[2]]))/ncol(wdbcNormalized))
})  

#----------------------------------Para Movement Libras---------------------------------------

modelosTrainvstestILS_Libras <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(LibrasNormalized$class, p =.50, list = FALSE)
  training=LibrasNormalized[indices,]
  test=LibrasNormalized[-indices,]
  
  time<-system.time(SolucionmodeloILS<-ILS(training,test,i*234567))
  list(SolucionmodeloILS,time)
})

modelosTestvsTrainILS_Libras <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(LibrasNormalized$class, p =.50, list = FALSE)
  test=LibrasNormalized[indices,]
  training=LibrasNormalized[-indices,]
  
  time<-system.time(SolucionmodeloILS<-ILS(training,test,i*234567))
  list(SolucionmodeloILS,time)
})

ReductionWDBC_ILS_SinInter_Libras<-lapply(seq_along(1:5),function(i){
  100*((ncol(LibrasNormalized)-sum(modelosTrainvstestILS_Libras[1,i][[1]][[2]]))/ncol(LibrasNormalized))
})                  

ReductionWDBC_ILS_Inter_Libras<-lapply(seq_along(1:5),function(i){
  100*((ncol(LibrasNormalized)-sum(modelosTestvsTrainILS_Libras[1,i][[1]][[2]]))/ncol(LibrasNormalized))
})  

#----------------------------------Para Arritmia--------------------------------------

modelosTrainvstestILS_Arr <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(AritmiaNormalized$class, p =.50, list = FALSE)
  training=AritmiaNormalized[indices,]
  test=AritmiaNormalized[-indices,]
  
  time<-system.time(SolucionmodeloILS<-ILS(training,test,i*234567))
  list(SolucionmodeloILS,time)
})

modelosTestvsTrainILS_Arr <- sapply(seq_along(1:5),  function(i){
  set.seed(i*9876543)
  indices<-createDataPartition(AritmiaNormalized$class, p =.50, list = FALSE)
  test=AritmiaNormalized[indices,]
  training=AritmiaNormalized[-indices,]
  time<-system.time(SolucionmodeloILS<-ILS(training,test,i*234567))
  list(SolucionmodeloILS,time)
})

ReductionWDBC_ILS_SinInter_Arr<-lapply(seq_along(1:5),function(i){
  100*((ncol(AritmiaNormalized)-sum(modelosTrainvstestILS_Arr[1,i][[1]][[2]]))/ncol(AritmiaNormalized))
})                  

ReductionWDBC_ILS_Inter_Arr<-lapply(seq_along(1:5),function(i){
  100*((ncol(AritmiaNormalized)-sum(modelosTestvsTrainILS_Arr[1,i][[1]][[2]]))/ncol(AritmiaNormalized))
})  


#----------------------------------data visualizations-----------------------------------
library(ggplot2)
#---------------------------------------------BOXPLOTS-----------------------------------
#----------------BMB for WDBC---------------
data.frame1<-data.frame(a=1:5,b=c(0.971831,0.9577465,0.971831,0.9577465,0.9507042,0.9649123,0.9649123,0.9473684,0.9508772,0.9649123))
data.frame2<-data.frame(a=1:5,b=c(0.9894366,0.9788732,0.9894366,0.9753521,0.9823944,0.9789474,0.9859649,0.9859649,0.9929825,0.9859649))

ggplot(data.frame1,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="blue"),data=data.frame2)+theme(legend.position = "none")
#----------------BMB for MOVEMENT LIBRAS--------
data.frame1ML_BMB<-data.frame(a=1:5,b=c(0.6777778,0.6833333,0.7277778,0.6944444,0.6777778,0.7333333,0.7111111,0.7111111,0.7222222,0.7444444))
data.frame2ML_BMB<-data.frame(a=1:5,b=c(0.7555556,0.7277778,0.75,0.7666667,0.7611111,0.7777778,0.7888889,0.7611111,0.7888889,0.7888889))

ML_BMB<-ggplot(data.frame1ML_BMB,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="green"),data=data.frame2ML_BMB)+theme(legend.position = "none")
#---------------BMB for ARRITMIA-------------
data.frame1ARR_BMB<-data.frame(a=1:5,b=c(0.6354167,0.625,0.6510417, 0.6510417, 0.65625,0.6391753,0.6443299,0.6082474,0.6494845,0.6082474))
data.frame2ARR_BMB<-data.frame(a=1:5,b=c(0.7395833,0.6822917,0.7395833,0.75,0.7083333,0.7268041,0.7164948, 0.7010309, 0.7010309,0.742268))

ARR_BMB<-ggplot(data.frame1ARR_BMB,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="green"),data=data.frame2ARR_BMB)+theme(legend.position = "none")


#----------------GRASP for WDBC---------------
data.frame1GRASP_WDBC<-data.frame(a=1:5,b=c(0.9471831,0.9366197,0.9542254,0.9366197,0.9225352,0.8947368,0.9157895,0.9052632,0.9578947,0.922807))
data.frame2GRASP_WDBC<-data.frame(a=1:5,b=c(0.9894366,0.9788732,0.9894366,0.971831,0.9823944,0.9824561,0.9824561,0.9824561,0.9894737, 0.9789474))

GRASP_WDBC<-ggplot(data.frame1GRASP_WDBC,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="blue"),data=data.frame2GRASP_WDBC)+theme(legend.position = "none")
#----------------GRASP for MOVEMENT LIBRAS--------
data.frame1ML_GRASP<-data.frame(a=1:5,b=c(0.55,0.6666667,0.3277778,0.4666667,0.5666667, 0.6777778,0.2777778,0.5944444,0.5055556,0.5333333))
data.frame2ML_GRASP<-data.frame(a=1:5,b=c(0.7555556,0.7722222,0.7888889,0.7944444,0.7833333,0.7944444,0.8,0.7944444,0.8166667,0.8333333))

ML_GRASP<-ggplot(data.frame1ML_GRASP,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="blue"),data=data.frame2ML_GRASP)+theme(legend.position = "none")
#---------------GRASP for ARRITMIA-------------
data.frame1ARR_GRASP<-data.frame(a=1:5,b=c(0.6354167,0.640625,0.6614583,0.6354167,0.65625,0.6340206,0.6494845,0.6701031,0.6340206,0.6340206))
data.frame2ARR_GRASP<-data.frame(a=1:5,b=c(0.8489583, 0.7916667,0.796875,0.8177083,0.8229167,0.8092784,0.8092784,0.8453608,0.8092784,0.7989691))

ARR_GRASP<-ggplot(data.frame1ARR_GRASP,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="blue"),data=data.frame2ARR_GRASP)+theme(legend.position = "none")


#----------------ILS for WDBC---------------
data.frame1ILS_WDBC<-data.frame(a=1:5,b=c(0.971831,0.915493,0.9647887,0.9471831,0.9683099,0.9508772,0.9578947, 0.9614035,0.9684211,0.9578947))
data.frame2ILS_WDBC<-data.frame(a=1:5,b=c(0.9964789,0.9788732,0.9894366,0.9823944,0.9823944,0.9824561,0.9859649, 0.9824561,0.9929825,0.9894737))

ILS_WDBC<-ggplot(data.frame1ILS_WDBC,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="blue"),data=data.frame2ILS_WDBC)+theme(legend.position = "none")
#----------------ILS for MOVEMENT LIBRAS--------
data.frame1ML_ILS<-data.frame(a=1:5,b=c(0.6777778,0.65,0.7055556,0.7166667,0.7111111,0.7388889,0.7166667,0.6944444,0.7277778,0.7166667))
data.frame2ML_ILS<-data.frame(a=1:5,b=c(0.75,0.75,0.7666667,0.7666667,0.7611111,0.7944444,0.7888889,0.7666667,0.7888889,0.7777778))

ML_ILS<-ggplot(data.frame1ML_ILS,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="blue"),data=data.frame2ML_ILS)+theme(legend.position = "none")
#---------------ILS for ARRITMIA-------------
data.frame1ARR_ILS<-data.frame(a=1:5,b=c(0.6510417,0.6041667,0.625,0.609375,0.6354167,0.5979381,0.628866,0.5927835,0.6082474,0.5721649))
data.frame2ARR_ILS<-data.frame(a=1:5,b=c(0.7760417,0.703125,0.75,0.765625,0.7291667,0.757732,0.7371134,0.7268041, 0.7216495,0.7628866))

ARR_ILS<-ggplot(data.frame1ARR_ILS,aes(a,b))+geom_boxplot(aes(a,b,colour="red"))+geom_boxplot(aes(a,b,colour="blue"),data=data.frame2ARR_ILS)+theme(legend.position = "none")


#---------------global comparation--------------

data.frame1<-data.frame(a=1:3,b=c(0.9666086,0.70055555,0.631131869))#3NN
data.frame2<-data.frame(a=1:3,b=c(0.983986767,0.770634943,0.7229321556))#BMB
data.frame3<-data.frame(a=1:3,b=c(0.9828185333,0.7932098667,0.8141526))#GRASP
data.frame4<-data.frame(a=1:3,b=c(0.98629108,0.7716049444,0.7453882778))#ILS


globalplot<-ggplot(data.frame1, aes(a, b)) +
  geom_line(aes(a, b, colour = "3NN"), data = data.frame1) +
  geom_line(aes(a, b, colour = "BMB"), data = data.frame2) +
  geom_line(aes(a, b, colour = "GRASP"), data = data.frame3) +
  geom_line(aes(a, b, colour = "ILS"), data = data.frame4) +
  scale_color_discrete(name="Algoritmos")

                                                                                                                                                                                                                                                                                                       
