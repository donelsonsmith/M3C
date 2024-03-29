#' pca: A principal component analysis function
#' 
#' This is a flexible PCA function that can be run on a standard data frame (or the M3C results object).
#' It is a wrapper for prcomp/ggplot2 code and can be customised with different colours and font sizes and more.
#' 
#' @param mydata Data frame or matrix or M3C results object: if dataframe/matrix should have samples as columns and rows as features
#' @param printres Logical flag: whether to print the PCA into current directory
#' @param K Numerical value: if running on the M3C results object, which value was the optimal K?
#' @param labels Character vector: if we want to just label with gender for example
#' @param text Character vector: if we wanted to label the samples with text IDs to look for outliers
#' @param axistextsize Numerical value: axis text size
#' @param legendtextsize Numerical value: legend text size
#' @param dotsize Numerical value: dot size
#' @param textlabelsize Numerical value: text inside plot label size 
#' @param legendtitle Character vector: text legend title   
#' @param controlscale Logical flag: whether to control the colour scale
#' @param scale Numerical value: 1=spectral palette, 2=manual low and high palette, 3=categorical labels
#' @param low Character vector: continuous scale low colour
#' @param high Character vector: continuous scale high colour
#' @param colvec Character vector: a series of colours in vector for categorical labels, e.g. c("sky blue", "gold")
#' @param printheight Numerical value: png height (default=20)
#' @param printwidth Numerical value: png width (default=22)
#' @param pcx Numerical value: which PC to plot on X axis (default=1)
#' @param pcy Numerical value: which PC to plot on Y axis (default=2)
#' @param scaler Logical flag: whether to scale the features of the input data (rows) (default=FALSE)
#'
#' @return A PCA plot object
#' @export
#'
#' @examples
#' PCA <- pca(mydata)

pca <- function(mydata, K = FALSE, printres = FALSE, labels = FALSE, text = FALSE, axistextsize = 18,
                legendtextsize = 18, dotsize = 5, textlabelsize = 4, legendtitle = 'Group',
                controlscale = FALSE, scale = 1, low = 'grey', high = 'red', 
                colvec = c("sky blue", "gold", "violet", "darkorchid", "slateblue", "forestgreen", 
                           "violetred", "orange", "midnightblue", "grey31", "black"),
                printheight = 20, printwidth = 22, pcx=1, pcy=2, scaler=FALSE){
  
  ## basic error handling
  if ( controlscale == TRUE && class(labels) %in% c( "character", "factor") && scale %in% c(1,2) ) {
    stop("when categorical labels, use scale=3")
  }
  if ( controlscale == TRUE && class(labels) %in% c( "numeric") && scale %in% c(3) ) {
    stop("when continuous labels, use scale=1 or scale=2")
  }
  if ( controlscale == FALSE && scale %in% c(2,3) ) {
    warning("if your trying to control the scale, please set controlscale=TRUE")
  }
  if (sum(is.na(labels)) > 0 && class(labels) %in% c('character','factor')){
    warning("there is NA values in the labels vector, setting to unknown")
    labels <- as.character(labels)
    labels[is.na(labels)] <- 'Unknown'
  }
  if (sum(is.na(text)) > 0 && class(text) %in% c('character','factor')){
    warning("there is NA values in the text vector, setting to unknown")
    text <- as.character(text)
    text[is.na(text)] <- 'Unknown'
  }
  
  ##
  message('***PCA wrapper function***')
  message('running...')
  
  ##
  if (scaler){
    mydata <- data.frame(t(scale(t(mydata))))
  }
  PC1 <- pcx
  PC2 <- pcy
  
  ##
  if (K == FALSE && labels == FALSE && text == FALSE){
    
    pca1 = prcomp(t(mydata))
    scores <- data.frame(pca1$x) # PC score matrix
    
    eigs <- pca1$sdev^2
    variance_percentage <- (eigs / sum(eigs))*100
    pc1var <- round(variance_percentage[PC1],digits=0)
    pc2var <- round(variance_percentage[PC2],digits=0)
    
    p <- ggplot(data = scores, aes(x = scores[,pcx], y = scores[,pcy]) ) + geom_point(aes(colour = factor(rep(1, ncol(mydata)))), size = dotsize) + 
      theme_bw() + 
      theme(legend.position = "none", panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            axis.text.y = element_text(size = axistextsize, colour = 'black'),
            axis.text.x = element_text(size = axistextsize, colour = 'black'),
            axis.title.x = element_text(size = axistextsize),
            axis.title.y = element_text(size = axistextsize)) +
      scale_colour_manual(values = colvec) +
      xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
      ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
    
    if (printres == TRUE){
      message('printing PCA to current directory...')
      png('PCA.png', height = printheight, width = printwidth, units = 'cm',
          res = 900, type = 'cairo')
      print(p) # print ggplot CDF in main plotting window
      dev.off()
    }
    
  }else if (K != FALSE && labels == FALSE){
    
    res <- mydata
    mydata <- res$realdataresults[[K]]$ordered_data
    annon <- res$realdataresults[[K]]$ordered_annotation
    annon$id <- row.names(annon)
    annon <- annon[match(colnames(mydata), annon$id),]
    
    pca1 = prcomp(t(mydata))
    scores <- data.frame(pca1$x) # PC score matrix
    
    eigs <- pca1$sdev^2
    variance_percentage <- (eigs / sum(eigs))*100
    
    pc1var <- round(variance_percentage[PC1],digits=0)
    pc2var <- round(variance_percentage[PC2],digits=0)
    
    p <- ggplot(data = scores, aes(x = scores[,pcx], y = scores[,pcy]) ) + geom_point(aes(colour = factor(annon$consensuscluster)), size = dotsize) + 
      theme_bw() + 
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            axis.text.y = element_text(size = axistextsize, colour = 'black'),
            axis.text.x = element_text(size = axistextsize, colour = 'black'),
            axis.title.x = element_text(size = axistextsize),
            axis.title.y = element_text(size = axistextsize),
            legend.title = element_text(size = legendtextsize),
            legend.text = element_text(size = legendtextsize)) + 
      guides(colour=guide_legend(title="Cluster"))  +
      xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
      ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
    
    if (printres == TRUE){
      message('printing PCA to current directory...')
      png('PCApostM3C.png', height = printheight, width = printwidth, units = 'cm',
          res = 900, type = 'cairo')
      print(p) # print ggplot CDF in main plotting window
      dev.off()
    }
    
  }else if (K == FALSE && labels != FALSE && text == FALSE){ #### KEY
    
    pca1 = prcomp(t(mydata))
    scores <- data.frame(pca1$x) # PC score matrix
    
    eigs <- pca1$sdev^2
    variance_percentage <- (eigs / sum(eigs))*100
    
    pc1var <- round(variance_percentage[PC1],digits=0)
    pc2var <- round(variance_percentage[PC2],digits=0)
    
    if (controlscale == TRUE){
      if (scale == 1){
        p <- ggplot(data = scores, aes(x = scores[,pcx], y = scores[,pcy]) ) + geom_point(aes(colour = labels), size = dotsize) + 
          theme_bw() + 
          theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                axis.text.y = element_text(size = axistextsize, colour = 'black'),
                axis.text.x = element_text(size = axistextsize, colour = 'black'),
                axis.title.x = element_text(size = axistextsize),
                axis.title.y = element_text(size = axistextsize),
                legend.title = element_text(size = legendtextsize),
                legend.text = element_text(size = legendtextsize)) + 
          #guides(colour=guide_legend(title=legendtitle)) +
          labs(colour = legendtitle) + scale_colour_distiller(palette = "Spectral") +
          xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
          ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
        #scale_colour_gradient(low="red", high="white")
        
      }else if (scale == 2){
        p <- ggplot(data = scores, aes(x = scores[,pcx], y = scores[,pcy]) ) + geom_point(aes(colour = labels), size = dotsize) + 
          theme_bw() + 
          theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                axis.text.y = element_text(size = axistextsize, colour = 'black'),
                axis.text.x = element_text(size = axistextsize, colour = 'black'),
                axis.title.x = element_text(size = axistextsize),
                axis.title.y = element_text(size = axistextsize),
                legend.title = element_text(size = legendtextsize),
                legend.text = element_text(size = legendtextsize)) + 
          #guides(colour=guide_legend(title=legendtitle)) +
          labs(colour = legendtitle) + #scale_colour_distiller(palette = "Spectral")
          scale_colour_gradient(low=low, high=high) +
          xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
          ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
        
      }else if (scale == 3){
        p <- ggplot(data = scores, aes(x = scores[,pcx], y = scores[,pcy]) ) + geom_point(aes(colour = labels), size = dotsize) + 
          theme_bw() + 
          theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                axis.text.y = element_text(size = axistextsize, colour = 'black'),
                axis.text.x = element_text(size = axistextsize, colour = 'black'),
                axis.title.x = element_text(size = axistextsize),
                axis.title.y = element_text(size = axistextsize),
                legend.title = element_text(size = legendtextsize),
                legend.text = element_text(size = legendtextsize)) + 
          #guides(colour=guide_legend(title=legendtitle)) +
          labs(colour = legendtitle) +
          scale_colour_manual(values = colvec) +
          xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
          ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
        
      }
    }else{
      p <- ggplot(data = scores, aes(x = scores[,pcx], y = scores[,pcy]) ) + geom_point(aes(colour = labels), size = dotsize) + 
        theme_bw() + 
        theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
              axis.text.y = element_text(size = axistextsize, colour = 'black'),
              axis.text.x = element_text(size = axistextsize, colour = 'black'),
              axis.title.x = element_text(size = axistextsize),
              axis.title.y = element_text(size = axistextsize),
              legend.title = element_text(size = legendtextsize),
              legend.text = element_text(size = legendtextsize)) + 
        #guides(colour=guide_legend(title=legendtitle)) +
        labs(colour = legendtitle) +
        xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
        ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
      
    }
    
    if (printres == TRUE){
      message('printing PCA to current directory...')
      png('PCAlabeled.png', height = printheight, width = printwidth, units = 'cm',
          res = 900, type = 'cairo')
      print(p) # print ggplot CDF in main plotting window
      dev.off()
    }
    
  }else if (K == FALSE && labels != FALSE && text != FALSE){ ##### KEY
    
    pca1 = prcomp(t(mydata))
    scores <- data.frame(pca1$x) # PC score matrix
    scores$label <- text
    
    eigs <- pca1$sdev^2
    variance_percentage <- (eigs / sum(eigs))*100
    
    pc1var <- round(variance_percentage[PC1],digits=0)
    pc2var <- round(variance_percentage[PC2],digits=0)
    
    if (controlscale == TRUE){
      if (scale == 1){
        p <- ggplot(data = scores, aes(x = PC1, y = PC2, label = label) ) + geom_point(aes(colour = labels), size = dotsize) + 
          theme_bw() + 
          theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                axis.text.y = element_text(size = axistextsize, colour = 'black'),
                axis.text.x = element_text(size = axistextsize, colour = 'black'),
                axis.title.x = element_text(size = axistextsize),
                axis.title.y = element_text(size = axistextsize),
                legend.title = element_text(size = legendtextsize),
                legend.text = element_text(size = legendtextsize)) + 
          #guides(colour=guide_legend(title=legendtitle)) +
          labs(colour = legendtitle) + scale_colour_distiller(palette = "Spectral")+ 
          geom_text(vjust="inward",hjust="inward",size=textlabelsize) +
          xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
          ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
        
        #scale_colour_gradient(low="red", high="white")
      }else if (scale == 2){
        p <- ggplot(data = scores, aes(x = PC1, y = PC2, label = label) ) + geom_point(aes(colour = labels), size = dotsize) + 
          theme_bw() + 
          theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                axis.text.y = element_text(size = axistextsize, colour = 'black'),
                axis.text.x = element_text(size = axistextsize, colour = 'black'),
                axis.title.x = element_text(size = axistextsize),
                axis.title.y = element_text(size = axistextsize),
                legend.title = element_text(size = legendtextsize),
                legend.text = element_text(size = legendtextsize)) + 
          #guides(colour=guide_legend(title=legendtitle)) +
          labs(colour = legendtitle) + #scale_colour_distiller(palette = "Spectral")
          scale_colour_gradient(low=low, high=high)+ 
          geom_text(vjust="inward",hjust="inward",size=textlabelsize) +
          xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
          ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
        
      }else if (scale == 3){
        p <- ggplot(data = scores, aes(x = PC1, y = PC2, label = label) ) + geom_point(aes(colour = labels), size = dotsize) + 
          theme_bw() + 
          theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                axis.text.y = element_text(size = axistextsize, colour = 'black'),
                axis.text.x = element_text(size = axistextsize, colour = 'black'),
                axis.title.x = element_text(size = axistextsize),
                axis.title.y = element_text(size = axistextsize),
                legend.title = element_text(size = legendtextsize),
                legend.text = element_text(size = legendtextsize)) + 
          #guides(colour=guide_legend(title=legendtitle)) +
          labs(colour = legendtitle) +
          scale_colour_manual(values = colvec)+ 
          geom_text(vjust="inward",hjust="inward",size=textlabelsize) +
          xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
          ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
        
      }
    }else{
      p <- ggplot(data = scores, aes(x = PC1, y = PC2, label = label) ) + geom_point(aes(colour = labels), size = dotsize) + 
        theme_bw() + 
        theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
              axis.text.y = element_text(size = axistextsize, colour = 'black'),
              axis.text.x = element_text(size = axistextsize, colour = 'black'),
              axis.title.x = element_text(size = axistextsize),
              axis.title.y = element_text(size = axistextsize),
              legend.title = element_text(size = legendtextsize),
              legend.text = element_text(size = legendtextsize)) + 
        #guides(colour=guide_legend(title=legendtitle)) +
        labs(colour = legendtitle) + 
        geom_text(vjust="inward",hjust="inward",size=textlabelsize) +
        xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
        ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
      
    }
    
    if (printres == TRUE){
      message('printing PCA to current directory...')
      png('PCAlabeled.png', height = printheight, width = printwidth, units = 'cm',
          res = 900, type = 'cairo')
      print(p) # print ggplot CDF in main plotting window
      dev.off()
    }
    
  }else if (K == FALSE && labels == FALSE && text != FALSE){
    
    pca1 = prcomp(t(mydata))
    scores <- data.frame(pca1$x) # PC score matrix
    scores$label <- text
    
    eigs <- pca1$sdev^2
    variance_percentage <- (eigs / sum(eigs))*100
    
    pc1var <- round(variance_percentage[PC1],digits=0)
    pc2var <- round(variance_percentage[PC2],digits=0)
    
    p <- ggplot(data = scores, aes(x = PC1, y = PC2, label = label) ) + 
      geom_point(aes(colour = factor(rep(1, ncol(mydata)))), size = dotsize) + 
      theme_bw() + 
      theme(legend.position = "none", panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            axis.text.y = element_text(size = axistextsize, colour = 'black'),
            axis.text.x = element_text(size = axistextsize, colour = 'black'),
            axis.title.x = element_text(size = axistextsize),
            axis.title.y = element_text(size = axistextsize)) +
      scale_colour_manual(values = colvec) + 
      geom_text(vjust="inward",hjust="inward",size=textlabelsize) +
      xlab(paste('PC',PC1,' (',pc1var,'% variance)',sep='')) +
      ylab(paste('PC',PC2,' (',pc2var,'% variance)',sep=''))
    
    if (printres == TRUE){
      message('printing PCA to current directory...')
      png('PCA.png', height = printheight, width = printwidth, units = 'cm',
          res = 900, type = 'cairo')
      print(p) # print ggplot CDF in main plotting window
      dev.off()
    }
    
  }else{
    message('no valid options detected')
  }
  
  message('done.')
  
  return(p)
}