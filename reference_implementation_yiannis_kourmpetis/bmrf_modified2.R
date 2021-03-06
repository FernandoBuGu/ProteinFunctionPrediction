# Functions used by bmrf.r script  


###########################################################
# BMRFz for one network and a domain matrix
# BMRF with network uncertainty
# Author: Yiannis Kourmpetis (yiannis.kourmpetis@wur.nl)
###########################################################
# Input arguments: 
# 1. File with the network topology, with format:
# protA protB confidence network_ID
#
# 2. GO Annotation file:
# protA GOterm evidence
#
# 3. Domain file

library(ROCR);
library(Matrix);
library(brglm);
library(mvtnorm); 
library(glmnet);
#library(GO.db);
#library(igraph); 


source("bmrf_functions.R");


# Load the data

bmrf = function(FILEnet, FILEann, FILEclust, outprobsfile, minGOsize, minFDsize, maxGOsize, maxFDsize) 
{
  burnin = 20;
  niter = 20;
  

  # Load, network, annotations and clusters

  A = loadSingleNet(FILEnet); # Loads the data in a single network (so netid is not used at the moment)    
  L = loadAnnFixedProteins(FILEann, A);
  D = loadAnnFixedProteins(FILEclust, A);
  
  # Take the goterms that are neither very general nor very sparse
  minGOsize = minGOsize;
  maxGOsize = (maxGOsize*nrow(A));

  Ls = colSums(L);
  sel = which(Ls >= minGOsize & Ls <= maxGOsize);
  L = L[,sel];
  
  # Do the same for clusters
  minClustsize = minFDsize; 
  maxClustsize = (maxFDsize*nrow(A));


  Ds = colSums(D);
  sel = which(Ds >= minClustsize & Ds <= maxClustsize);
  D = D[,sel];
  
  u = rowSums(L);
  U = which(u == 0);
      
  tglm <- 0
  tpost <- 0
  tcal <- 0
  
  for(i in 1:ncol(L))
  {
    ta <- Sys.time()

    cat(i,ncol(L), sep="/");      
    #Make the elastic net fitting and predictions:
    Lsingle = L[,i];
    Lsingle[U] = -1;
  
    glmnetpred = try(glmnetDalpha(Y = Lsingle, X = D, MAXVAR = (ncol(D)-1)), silent=FALSE);
    if(class(glmnetpred) == 'try-error')
    {
      next;
    }

    tglm <- tglm + (Sys.time() - ta)
      
    # Prepare the Labellings vector
      

    # Run BMRFz 
    ta <- Sys.time()
    posteriors = try(BMRFz(A=A, L = Lsingle, D = glmnetpred, burnin = burnin, niter = niter), silent=FALSE);
    if(class(posteriors) == 'try-error')
    {
      # If BMRFz does not run for any reason, report the EN probs only
      next;
    }
    tpost <- tpost + (Sys.time() - ta)

    ta <- Sys.time()
    posteriors = calibrate(posteriors);
    
    names(posteriors) = rownames(A);
    out = cbind(rownames(A), round(posteriors,5));
    go = colnames(L)[i];

    go = rep(x=colnames(L)[i], times=length(posteriors));
    probs = cbind(names(posteriors), go, posteriors);
    write.table(probs, file= outprobsfile, append=TRUE, quote=F, row.names=F, col.names=F, sep = "\t");     
    tcal <- tcal + (Sys.time() - ta)
    cat("  tglm: ", tglm/i, "  tpost: " , tpost/i, "  tcal: ", tcal/i, "\n" )
  }
  i <- ncol(L)
  cat("  tglm: ", tglm/i, "  tpost: " , tpost/i, "  tcal: ", tcal/i, "\n" )
}
