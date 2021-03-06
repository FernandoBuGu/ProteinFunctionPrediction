#Script to annotate the non-GO-specific features. Creates one file per gene

    #MSc thesis bioinfomratics WUR. Protein function prediction for poorly annotated species.
    #Author: Fernando Bueno Gutierrez
    #email1: fernando.buenogutierrez@wur.nl
    #email2: fernando.bueno.gutie@gmail.com

start.time <- Sys.time()

S<-c(1,2,35,5,6,7,8) #sequence of prearson correlation thresholds. Note that it is required that the files have been created previously ("AUC_for_different_Pearson" file)
library("doParallel")
library("parallel")
library("foreach")



net<-read.table("big_topless035.tsv")  #network file for the default pearson corr. threshold
genes<-data.frame(net$V1)
genes2<-data.frame(net$V2)




colnames(genes)<-"gene"; colnames(genes2)<-"gene"
only_names<-unique(rbind(genes,genes2))
genes<-unique(rbind(genes,genes2))

setwd("/mnt/nexenta/bueno002/chickens/")

append_all<-function(number){
#annotates features for a gene. The features are non-GO-specific features.
#In:
    #number: int, a pearson corr. threshold. Inpuuts will be the integeres in "S".

#Out:
    #genes: data frame with the values of the features for the gene of interest.


    list_of_files<-c("rbind_upvalid_upNONvalid_01","big_topless01.tsv","to_uppropagated_valid_01","to_uppropagated_NONvalid_01") #GOfile, net, go_beforeUP_valid, go_beforeUP_nonvalid
    list_of_files<-gsub("1", number, list_of_files) #replace "1" (default) by "number"

    go<-read.table(list_of_files[1]) #define the GO file given the Pearson correlation thershold
    net<-read.table(list_of_files[2],fill=T) #define the network file given the Pearson correlation thershold
    net<-net[complete.cases(net), ]
    net = net[(which(nchar(as.character(net$V1)) > 1)),]
    net = net[(which(nchar(as.character(net$V2)) > 1)),]

    

    #no_GO: nº of GO terms that the gene is associated with
    no_goes<-table(go$V1)
    no_goes<-data.frame(no_goes)
    colnames(no_goes)<-c("gene",paste("no_GO",number,sep="_"))
    genes<-merge(genes,no_goes,by="gene",all.x=T,all.y=F)
    NCOL<-as.numeric(dim(genes)[2])


    #no_GO_v: nº of validated GO terms that the gene is associated with
    go_v<-go[go$V3=="valid",]
    no_goes_v<-table(go_v$V1)
    no_goes_v<-data.frame(no_goes_v)
    colnames(no_goes_v)<-c("gene",paste("no_GO_v",number,sep="_"))
    genes<-merge(genes,no_goes_v,by="gene",all.x=T,all.y=F)

    # no_GO before uppropagate
    go_befUP<-read.table(list_of_files[3])
    go_befUP$V3<-"valid"
    go_befUP_non<-read.table(list_of_files[4])
    print("dim(go_befUP_non)")
    print(dim(go_befUP_non))
    go_befUP_non$V3<-"NONvalid"
    go_befUP<-rbind(go_befUP,go_befUP_non)

    no_goes<-table(go_befUP$V1)
    no_goes<-data.frame(no_goes)
    colnames(no_goes)<-c("gene",paste("no_GO_bUP",number,sep="_"))
    genes<-merge(genes,no_goes,by="gene",all.x=T,all.y=F)


    # no_GO_v before uppropagate
    go_v<-go[go_befUP$V3=="valid",]
    no_goes_v<-table(go_v$V1)
    no_goes_v<-data.frame(no_goes_v)
    colnames(no_goes_v)<-c("gene",paste("no_GO_v_bUP",number,sep="_"))
    genes<-merge(genes,no_goes_v,by="gene",all.x=T,all.y=F)


    # no_neigh: number of neighbours
    net<-read.table(list_of_files[2],fill=T)
    net<-net[complete.cases(net), ]
    N1<-data.frame(as.character(net$V1))
    colnames(N1)<-"g"
    N2<-data.frame(as.character(net$V2))
    colnames(N2)<-"g"
    N<-rbind(N1,N2)
    colnames(N)<-"g"
    Ncount<-table(N$g)
    DF_count<-data.frame(Ncount)
    colnames(DF_count)<-c("gene",paste("no_neigh",number,sep="_"))
    genes<-merge(genes,DF_count,by="gene",all.x=T,all.y=F)



    #no_neigh with that are assoviated with more than 2 GO terms
    more_2GOES<-as.character(unique(genes$gene[genes[,NCOL]>2]))
    net<-net[as.character(net$V1) %in% more_2GOES & as.character(net$V2) %in% more_2GOES,]
    N1<-data.frame(as.character(net$V1))
    colnames(N1)<-"g"
    N2<-data.frame(as.character(net$V2))
    colnames(N2)<-"g"
    N<-rbind(N1,N2)
    colnames(N)<-"g"
    Ncount<-table(N$g)
    DF_count<-data.frame(Ncount)
    colnames(DF_count)<-c("gene",paste("no_neigh_2GOES",number,sep="_"))
    genes<-merge(genes,DF_count,by="gene",all.x=T,all.y=F)



    #no_neigh with that are assoviated with more than 5 GO terms
    more_5GOES<-as.character(unique(genes$gene[genes[,NCOL]>5]))
    net<-net[as.character(net$V1) %in% more_5GOES & as.character(net$V2) %in% more_5GOES,]
    N1<-data.frame(as.character(net$V1))
    colnames(N1)<-"g"
    N2<-data.frame(as.character(net$V2))
    colnames(N2)<-"g"
    N<-rbind(N1,N2)
    colnames(N)<-"g"
    Ncount<-table(N$g)
    DF_count<-data.frame(Ncount)
    colnames(DF_count)<-c("gene",paste("no_neigh_5GOES",number,sep="_"))
    genes<-merge(genes,DF_count,by="gene",all.x=T,all.y=F)

    return(genes)
}



#Run in parallel for all the Pearson correlations thersholds considered in S
cores=detectCores()
cl <- makeCluster(cores[1]-1)
registerDoParallel(cl)
clusterExport(cl,varlist=ls(),envir=environment())
a<-foreach(i = S, .packages='Matrix', .combine="c") %dopar% { append_all(i) }
stopCluster(cl)
#


a<-a[names(a)!="gene"]

df <- data.frame(matrix(unlist(a), ncol=49),stringsAsFactors=FALSE)
colnames(df)<-names(a)
df2<-cbind(only_names,df)

write.table(df2, file="/mnt/nexenta/bueno002/part2_k10/AAAnoGOspec_info", col.names = T, row.names = F, quote = F, sep="\t") #Write one file pergene




