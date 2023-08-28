# showing carob's fertilizer group data
path <- getwd()
df <- read.csv("C:/Users/User/Documents/carob1/data/compiled/carob-fertilizer.csv")

# minimize to EAC countries i.e DRC, Tanzania, Kenya, Burundi, Rwanda, South Sudan(we use Sudan like accorded in dataset), 
# and Uganda.

# subsetting to remain with EAC countries
dd <- df[df$country %in% c("Democratic Republic of the Congo","Tanzania","Kenya", "Burundi", "Rwanda","Uganda"),] 

# subsetting to remain with variables of interest
dd <- dd[,c("country","longitude","latitude","crop","N_fertilizer","P_fertilizer",
            "K_fertilizer")] 

# calculating missing values
missing <- sapply(dd, function(x) sum(is.na(x)) / length(x) * 100)
miss <- data.frame(Variables = names(missing), Missing_Percentage = missing)
row.names(miss) <- NULL

# Removing NAs from NPK fertilizer inputs(lost 6052 entries)
dr <- dd[!is.na(dd$N_fertilizer),]
dr <- dr[!is.na(dr$P_fertilizer),]
dr <- dr[!is.na(dr$K_fertilizer),]
# 
library(leaflet)
places <- data.frame(latitude = d.M.N.L$y,longitude = d.M.N.L$x)
map <- leaflet(places) %>% addTiles() # adds default map tiles
map <- map %>% addMarkers(lng = ~longitude, lat = ~latitude)
map

# Removing NAs lon and lat entries(lost 5 entries) # EGB actually 105
dr <- dr[!is.na(dr$latitude),]
dr <- dr[!is.na(dr$longitude),]

# fixing datatypes
# EGB: Not necessary
dr$longitude <- as.numeric(dr$longitude)
dr$K_fertilizer <- as.numeric(dr$K_fertilizer)

# # Create a frequency table of the crops
# level <- table(dr$country)
# 
# # Create a ggplot2 bar plot with reordered fertilizer types
# library(ggplot2)
# ggplot(dr, aes(x = reorder(country, -level[country]), fill = country)) +
#   geom_bar() +
#   labs(x = "Country", y = "Frequency",title = "Frequency distribution of Country") +
#   guides(fill = "none")

# # N,P,K fertilizer boxplots
# fert <- dr[,c("N_fertilizer","P_fertilizer","K_fertilizer")]
# boxplot(fert, main = "Boxplot of N,P,K Fertilizers")

# removing duplicate entries(lost 1469 entries)

library(terra)
# EGB: Remove points outside AOI
KEN <- terra::vect("C:/Users/User/Downloads/gadm41_KEN.gpkg", layer = "ADM_ADM_0")
TZA <- terra::vect("C:/Users/User/Downloads/gadm41_TZA.gpkg", layer = "ADM_ADM_0")
RWA <- terra::vect("C:/Users/User/Downloads/gadm41_RWA.gpkg", layer = "ADM_ADM_0")
UGA <- terra::vect("C:/Users/User/Downloads/gadm41_UGA.gpkg", layer = "ADM_ADM_0")
BDI <- terra::vect("C:/Users/User/Downloads/gadm41_BDI.gpkg", layer = "ADM_ADM_0")
EAC <- terra::union(terra::union(terra::union(terra::union(KEN,TZA),RWA),UGA),BDI)
dr <- terra::as.data.frame(terra::intersect(terra::vect(dr, geom=c("longitude", "latitude")), EAC), geom	 = "XY")

# # calculating quantiles to determine where they should fall dependent on variable distribution
# 
# summary_stats <- c(0.00, 0.00, 22.5, 17.11, 30.00, 90.00) # P fertilizer
# summary_stats <- c(0.00, 0.00, 0.00, 41.4, 100, 200.00) # N
# summary_stats <- c(0.00, 0.00, 0, 18.85, 30.00, 75.00) # K
# 
# # calculating quantiles
# quantiles <- quantile(summary_stats, probs = c(0, 0.5, 1))
# # defining the threshold based on the median
# threshold <- quantiles[2]
# # creating quantile percentages
# quantile_percentages <- round(quantiles / max(summary_stats) * 100, 2)

# create groups of fertilier inputs
dr$N_levels <- cut(dr$N_fertilizer, breaks = quantile(dr$N_fertilizer, probs = c(0.33,0.66,0.99)), 
                   labels = c("Low","High"), 
                   include.lowest = TRUE, right = FALSE)

dr$P_levels <- cut(dr$P_fertilizer, breaks = quantile(dr$P_fertilizer, probs = c(0,0.5,1)), 
                   labels = c("Low","High"), 
                   include.lowest = TRUE, right = FALSE)
# EGB: Changing to manual cuts
dr$K_levels <- cut(dr$K_fertilizer, breaks = quantile(dr$K_fertilizer, probs = c(0.5,0.75,1)), 
                   labels = c("Low","High"),
                   include.lowest = TRUE, right = FALSE)
# dr <- unique(dr[,c(lati])
# EGB: Nice! But also subset for crop!
# subsetting per fertilizer level
# N_levels
# First, low amounts
# de <- dr[dr$N_levels == "Low",]
d.M.N.L <- unique(dr[dr$N_levels == "Low" & dr$crop == "maize",c("y","x")])
d.M.N.L<- na.omit(d.M.N.L)

d.M.N.H <- unique(dr[dr$N_levels == "High" & dr$crop == "maize",c("y","x")])
d.M.N.H <- na.omit(d.M.N.H)

# d.S.N.L <- unique(dr[dr$N_levels == "Low" & dr$crop == "soybean",c("y","x")])
# d.S.N.H <- unique(dr[dr$N_levels == "High" & dr$crop == "soybean",c("y","x")])
# d.B.N.L <- unique(dr[dr$N_levels == "Low" & dr$crop == "common bean",c("y","x")])
# d.B.N.H <- unique(dr[dr$N_levels == "High" & dr$crop == "common bean",c("y","x")])
# # subsetting unique for lon and lat
# dt <- unique(de[,c("latitude","longitude")])

# EGB: Noooo! raster = TRUE 
# extracting bio climatic conditions per coordinate

source("C:/Users/User/Documents/AgWISE-generic/00_dataProcessing/worldclim.R")
install.packages("raster")
library(raster)

f <- worldclim(var=c("tavg", "tmin", "tmax", "prec","elev","bio"),10,raster = TRUE,coords = data.frame(X = c(terra::ext(EAC)[1][[1]], terra::ext(EAC)[2][[1]]),
                                                                                                       Y = c(terra::ext(EAC)[3][[1]], terra::ext(EAC)[4][[1]])))

ff <- worldclim(var=c("tavg", "tmin", "tmax", "prec","elev","bio"),10,raster = FALSE,coords = data.frame(X = c(terra::ext(EAC)[1][[1]], terra::ext(EAC)[2][[1]]),
                                                                                                         Y = c(terra::ext(EAC)[3][[1]], terra::ext(EAC)[4][[1]])))

install.packages("dismo")
library("dismo")
install.packages("rgeos")
library("rgeos")
library("terra")
install.packages("rJava")
library("rJava")
# 
# install.packages("knitr")
# library("knitr")
# knitr::opts_knit$set(root.dir = 'C:/Users/User/Documents/carob1/maxent_test_run')
# opts_chunk$set(tidy.opts=list(width.cutoff=60),tidy=TRUE)
# 
# # prepare folders for data input and output
# if (!file.exists("C:/Users/User/Documents/carob1/data")) dir.create("C:/Users/User/Documents/carob1/data")
# if (!file.exists("C:/Users/User/Documents/carob1/data/worldclim")) dir.create("C:/Users/User/Documents/carob1/data/worldclim")
# if (!file.exists("C:/Users/User/Documents/carob1/data/studyarea")) dir.create("C:/Users/User/Documents/carob1/data/studyarea")
# if (!file.exists("C:/Users/User/Documents/carob1/output")) dir.create("C:/Users/User/Documents/carob1/output")
# require(utils)
# # download climate data from worldclim.org
# utils::download.file(url = "http://biogeo.ucdavis.edu/data/climate/worldclim/1_4/grid/cur/tavg_10m_bil.zip", 
#                      destfile = paste0("../data/bioclim/bio_10m_bil.zip"))
# utils::unzip("../data/bioclim/bio_10m_bil.zip", exdir = "../data/bioclim/")
# 
# # This searches for all files that are in the path
# # 'data/bioclim/' and have a file extension of .bil. You can
# # edit this code to reflect the path name and file extension
# # for your environmental variables
# clim_list <- list.files("../data/bioclim/", pattern = ".bil$", 
#                         full.names = T)  # '..' leads to the path above the folder where the .rmd file is located
# 
# # stacking the bioclim variables to process them at one go
# clim <- raster::stack(clim_list)
# 
# 

ncell(f)
set.seed(23) 
bg <- sampleRandom(x=raster::stack(f),
                   size=ncell(f),
                   na.rm=T, #removes the 'Not Applicable' points  
                   sp=T) # return spatial points 

# viewing first env condition on plot
terra::plot(f[[1]]) 

# add the background points to the plotted raster
terra::plot(bg,add=T)

# add the occurrence data to the plotted raster
points(x = d.M.N.L$x, y = d.M.N.L$y, col ="blue", pch = "+")
terra::plot(EAC, add = T)

# bio features for d
ott <- terra::extract(f,d.M.N.L[,c("y","x")]) 
v <- usdm::vifstep(ott[,2:ncol(ott)])

# randomly select 70% for training
selected <- sample(1:nrow(d.M.N.L), nrow(d.M.N.L) * 0.7)

prc_train <- d.M.N.L[selected, ]  # this is the selection to be used for model training
prc_test <- d.M.N.L[-selected, ]  # this is the opposite of the selection

# extracting env conditions for training occ from the raster
# stack; a data frame is returned (i.e multiple columns)
p <- terra::extract(f, prc_train[,c("x", "y")])
# p_df <- data.frame(x = prc_train$x, y = prc_train$y, values = p)
# library(sf)
# sf_obj <- st_as_sf(p_df, coords = c("x", "y"))

# env conditions for testing occ
p_test <- terra::extract(f, prc_test[,c("x", "y")])

# extracting env conditions for background
a <- terra::extract(f, terra::vect(bg))

# repeat the number 1 as many numbers as the number of rows
# in p, and repeat 0 as the rows of background points
pa <- c(rep(1, nrow(p)), rep(0, nrow(a)))

# (rep(1,nrow(p)) creating the number of rows as the p data
# set to have the number '1' as the indicator for presence;
# rep(0,nrow(a)) creating the number of rows as the a data
# set to have the number '0' as the indicator for absence;
# the c combines these ones and zeros into a new vector that
# can be added to the Maxent table data frame with the
# environmental attributes of the presence and absence
# locations
pder <- as.data.frame(rbind(p, a))

# # dimensionality reduction to select variables of interest
# pca_result <- prcomp(pder[,2:ncol(pder)], scale. = TRUE)
# summary(pca_result)
# plot(pca_result) #PC1 explains the most variance followed by 2 and 3
# 
# loadings <- pca_result$rotation  # Principal component loadings
# scores <- pca_result$x  # Transformed data (scores)
# 
# # Plot the proportion of variance explained per PC as %
# library(ggplot2)
# eigenvalues <- pca_result$sdev^2
# 
# # Create scree plot
# par(mar = c(5, 5, 4, 2) + 0.1)
# plot(1:length(eigenvalues), eigenvalues, type = "b", pch = 19, xlab = "Principal Components", ylab = "Eigenvalues",main = "PCA Scree plot showing variance per PC")
# 
# # Calculate the cumulative explained variance
# cumulative_variance <- cumsum(pca_result$sdev^2 / sum(pca_result$sdev^2))
# 
# # Plot the cumulative explained variance
# plot(cumulative_variance, type = "b", xlab = "Number of Components", ylab = "Cumulative Explained Variance")
# 
# # Determine the threshold based on the scree plot or cumulative explained variance
# threshold <- 0.95  # Set your desired threshold
# 
# # Find the number of components that meet the threshold
# num_components <- which(cumulative_variance >= threshold)[1]
# 
# # Retain the desired number of components in the PCA
# selected_components <- scores[, 1:num_components]
# 
# # Determine the variables that contribute highly to each principal component based on the loadings.
# # Considering variables with absolute loadings greater than a threshold 0.15 as highly
# # contributing variables. Here's an example for the first principal component (PC1)
# library(tibble)
# pc_loadings <- as.data.frame(loadings[, 1:num_components])
# pc_loadings <- rownames_to_column(pc_loadings, var = "variables")
# 
# # extracting important variables per PC
# high_contrib_vars_pc1 <- pc_loadings[((abs(pc_loadings[,2:ncol(pc_loadings)]) > 0.15)[,1]),1]
# 
# # high_contrib_vars_pc1
# # [1] "wc2.1_10m_tavg_01" "wc2.1_10m_tavg_02" "wc2.1_10m_tavg_03" "wc2.1_10m_tavg_04" "wc2.1_10m_tavg_05"
# # [6] "wc2.1_10m_tavg_06" "wc2.1_10m_tavg_07" "wc2.1_10m_tavg_08" "wc2.1_10m_tavg_12" "wc2.1_10m_tmax_04"
# # [11] "wc2.1_10m_bio_1"   "wc2.1_10m_bio_8"   "wc2.1_10m_bio_10"  "wc2.1_10m_bio_11" 
# 
# high_contrib_vars_pc2 <- pc_loadings[((abs(pc_loadings[,2:ncol(pc_loadings)]) > 0.15)[,2]),1]
# 
# # high_contrib_vars_pc2
# # [1] "wc2.1_10m_prec_01" "wc2.1_10m_prec_02" "wc2.1_10m_prec_05" "wc2.1_10m_prec_06" "wc2.1_10m_prec_07"
# # [6] "wc2.1_10m_prec_08" "wc2.1_10m_prec_09" "wc2.1_10m_prec_10" "wc2.1_10m_prec_12" "wc2.1_10m_bio_3"  
# # [11] "wc2.1_10m_bio_4"   "wc2.1_10m_bio_14"  "wc2.1_10m_bio_15"  "wc2.1_10m_bio_17"  "wc2.1_10m_bio_19" 
# 
# high_contrib_vars_pc3 <- pc_loadings[((abs(pc_loadings[,2:ncol(pc_loadings)]) > 0.15)[,3]),1]
# 
# # high_contrib_vars_pc3
# # [1] "wc2.1_10m_prec_01" "wc2.1_10m_prec_02" "wc2.1_10m_prec_03" "wc2.1_10m_prec_04" "wc2.1_10m_prec_05"
# # [6] "wc2.1_10m_prec_12" "wc2.1_10m_bio_2"   "wc2.1_10m_bio_7"   "wc2.1_10m_bio_12"  "wc2.1_10m_bio_13" 
# # [11] "wc2.1_10m_bio_16"  "wc2.1_10m_bio_18" 
# 
# high_contrib_vars_pc4 <- pc_loadings[((abs(pc_loadings[,2:ncol(pc_loadings)]) > 0.15)[,4]),1]
# 
# # high_contrib_vars_pc4
# # [1] "wc2.1_10m_tmax_10" "wc2.1_10m_tmax_11" "wc2.1_10m_prec_02" "wc2.1_10m_prec_06" "wc2.1_10m_prec_07"
# # [6] "wc2.1_10m_prec_08" "wc2.1_10m_prec_09" "wc2.1_10m_bio_2"   "wc2.1_10m_bio_4"   "wc2.1_10m_bio_5"  
# # [11] "wc2.1_10m_bio_7"   "wc2.1_10m_bio_12"  "wc2.1_10m_bio_13"  "wc2.1_10m_bio_16"  "wc2.1_10m_bio_19"
# 
# high_contrib_vars_pc5 <- pc_loadings[((abs(pc_loadings[,2:ncol(pc_loadings)]) > 0.15)[,5]),1]
# 
# # high_contrib_vars_pc5
# # [1] "wc2.1_10m_tmax_09" "wc2.1_10m_tmax_10" "wc2.1_10m_prec_01" "wc2.1_10m_prec_02"
# # [5] "wc2.1_10m_prec_11" "wc2.1_10m_prec_12" "wc2.1_10m_bio_2"   "wc2.1_10m_bio_7"  
# # [9] "wc2.1_10m_bio_13"  "wc2.1_10m_bio_15"  "wc2.1_10m_bio_16"
# 
# high_contrib_vars_pc6 <- pc_loadings[((abs(pc_loadings[,2:ncol(pc_loadings)]) > 0.15)[,6]),1]
# 
# # high_contrib_vars_pc6
# # [1] "wc2.1_10m_prec_01" "wc2.1_10m_prec_02" "wc2.1_10m_prec_04" "wc2.1_10m_prec_05" "wc2.1_10m_prec_10"
# # [6] "wc2.1_10m_prec_11" "wc2.1_10m_bio_3"   "wc2.1_10m_bio_7"   "wc2.1_10m_bio_13"  "wc2.1_10m_bio_14" 
# # [11] "wc2.1_10m_bio_15"  "wc2.1_10m_bio_17"  "wc2.1_10m_bio_18" 
# 
# # combine all variables of interest for every PC into one vector
# high_var_1_6 <- c(high_contrib_vars_pc1,high_contrib_vars_pc2,high_contrib_vars_pc3,high_contrib_vars_pc4,high_contrib_vars_pc5,high_contrib_vars_pc6) # 79 variables with some repetition
# final_high_vars <- unique(high_var_1_6) # down to 46 variables of importance
# 
# # check for multicollinearity in the chosen variables
# scaled <- scale(pder[,final_high_vars])
# cor_matrix <- cor(scaled)
# 
# # Generate a correlation plot
# # install.packages("corrplot")
# # library(corrplot)
# # library(lattice)
# # install.packages("caret")
# # library(caret)
# # install.packages("vctrs")
# # update.packages("vctrs")
# 
# # plot correlation matrix
# corrplot(cor_matrix, method = "circle", order = "hclust", tl.cex = 0.7, number.cex = 0.7, tl.col = "black")
# cutoff = 0.8
# cor_mask <- abs(cor_matrix) >= cutoff
# cor_filtered <- cor_matrix * cor_mask
# corrplot(cor_filtered, method = "circle", order = "hclust", tl.cex = 0.7, number.cex = 0.7, tl.col = "black") # cor matrix of variables whose coeff is =>0.8
# 
# # Final variables that don't exhibit high correlation
# 
# selected_vars <- c("wc2.1_10m_bio_18","wc2.1_10m_bio_3","wc2.1_10m_bio_15","wc2.1_10m_bio_2","wc2.1_10m_bio_14","wc2.1_10m_bio_12","wc2.1_10m_bio_7",
#                    "wc2.1_10m_prec_10","wc2.1_10m_prec_04","wc2.1_10m_prec_03","wc2.1_10m_prec_06","wc2.1_10m_tavg_09")
# 
# # confirming no multicollinearity
# corrplot(cor(scaled[,selected_vars]), method = "color", type = "upper", order = "hclust",
#          tl.col = "black", tl.srt = 45, addCoef.col = "black", number.cex = 0.8)

# train Maxent with spatial data
# mod <- maxent(x=clim,p=occ_train)

# train Maxent with tabular data
mod <- maxent(x=pder[,2:ncol(pder)], ## env conditions
              p=pa,   ## 1:presence or 0:absence
              path=paste0("C:/Users/User/Documents/carob1/output"), ## folder for maxent output; 
              # if we do not specify a folder R will put the results in a temp file, 
              # and it gets messy to read those. . .
              args=c("responsecurves") ## parameter specification
)
# the maxent functions runs a model in the default settings. To change these parameters,
# you have to tell it what you want...i.e. response curves or the type of features

# view the maxent model in a html brower
mod

# example 1, project to study area [raster]
ped1 <- predict(mod, f)  # studyArea is the clipped rasters 
head(ped1)
plot(ped1)  # plot the continuous prediction
points(d.M.N.L$x,d.M.N.L$y)
terra::plot(EAC, add = T)

# example 3, project with training occurrences [dataframes]
ped3 <- predict(mod, p)
head(ped3)
#plot(ped3)
points(d.M.N.L$x,d.M.N.L$y)
hist(ped3)
terra::plot(EAC, add = T)

mod_eval_train <- dismo::evaluate(p = p, a = a, model = mod)
print(mod_eval_train)


mod_eval_test <- dismo::evaluate(p = p_test, a = a, model = mod)
print(mod_eval_test)

plot(mod_eval_train, 'ROC')
plot(mod_eval_train, 'TPR')
boxplot(mod_eval_train)
density(mod_eval_test)

# calculate thresholds of models

thd1 <- threshold(mod_eval_train, "no_omission")  # 0% omission rate 
thd2 <- threshold(mod_eval_train, "spec_sens")  # highest TSS

# plotting points that are above the previously calculated
# threshold value

plot(ped1 >= thd1)
terra::plot(EAC, add = T)

##4 Maxent parameters ###4.1 Select features

#####Thread 21
# load the function that prepares parameters for maxent
source("https://raw.githubusercontent.com/shandongfx/workshop_maxent_R/master/code/Appendix2_prepPara.R")

mod1_autofeature <- maxent(x=pder[,selected_vars], 
                           ## env conditions, here we selected only 13 predictors from prior feature selection
                           p=pa,
                           ## 1:presence or 0:absence
                           path="C:/Users/User/Documents/carob1/output/maxent_outputs1_auto",
                           ## this is the folder you will find maxent output
                           args=prepPara(userfeatures=NULL) ) 
## default is autofeature

# or select Linear& Quadratic features
mod1_lq <- maxent(x=pder[,selected_vars],
                  p=pa,
                  path=paste0("C:/Users/User/Documents/carob1/output/maxent_outputs1_lq"),
                  args=prepPara(userfeatures="LQ") ) 
## default is autofeature, here LQ represents Linear& Quadratic
## (L-linear, Q-Quadratic, H-Hinge, P-Product, T-Threshold)

###4.2 Change beta-multiplier

#####Thread 22

#change betamultiplier for all features
mod2 <- maxent(x=pder[,selected_vars], 
               p=pa, 
               path=paste0("C:/Users/User/Documents/carob1/output/maxent_outputs2_0.5"), 
               args=prepPara(userfeatures="LQ",
                             betamultiplier=0.5) ) 

mod2 <- maxent(x=pder[,selected_vars], 
               p=pa, 
               path=paste0("C:/Users/User/Documents/carob1/output/maxent_outputs2_complex"), 
               args=prepPara(userfeatures="LQH",
                             ## include L, Q, H features
                             beta_lqp=1.5, 
                             ## use different betamultiplier for different features
                             beta_hinge=0.5 ) ) 

###4.3 Specify projection layers

#####Thread 23

# note: (1) the projection layers must exist in the hard disk (as relative to computer RAM); 
# (2) the names of the layers (excluding the name extension) must match the names 
# of the predictor variables; 
mod3 <- maxent(x=pder[,selected_vars], 
               p=pa, 
               path=paste0("C:/Users/User/Documents/carob1/output/maxent_outputs3_prj1"), 
               args=prepPara(userfeatures="LQ",
                             betamultiplier=1,
                             projectionlayers="/Users/iel82user/Google Drive/1_osu_lab/projects/2017_7_workshop_enm_R/data/studyarea") ) 

# load the projected map
ped <- raster(paste0("C:/Users/User/Documents/carob1/output/maxent_outputs3_prj1/species_studyarea.asc"))
plot(ped)

# we can also project on a broader map, but please 
# caustion about the inaccuracy associated with model extrapolation.
mod3 <- maxent(x=pder[,selected_vars], 
               p=pa, 
               path=paste0("../output/maxent_outputs3_prj2"), 
               args=prepPara(userfeatures="LQ",
                             betamultiplier=1,
                             projectionlayers="/Users/iel82user/Google Drive/1_osu_lab/projects/2017_7_workshop_enm_R/data/bioclim") ) 
# plot the map
ped <- raster(paste0("../output/maxent_outputs3_prj2/species_bioclim.asc"))
plot(ped)

# simply check the difference if we used a different betamultiplier
mod3_beta1 <- maxent(x=pder[,selected_vars], 
                     p=pa, 
                     path=paste0("C:/Users/User/Documents/carob1/output/maxent_outputs3_prj3"), 
                     args=prepPara(userfeatures="LQ",
                                   betamultiplier=100, 
                                   ## for an extreme example, set beta as 100
                                   projectionlayers="/Users/iel82user/Google Drive/1_osu_lab/projects/2017_7_workshop_enm_R/data/bioclim") ) 
ped3 <- raster(paste0("../output/maxent_outputs3_prj3/species_bioclim.asc"))
plot(ped-ped3) ## quickly check the difference between the two predictions

###4.4 Clamping function

#####Thread 24

# enable or disable clamping function; note that clamping
# function is involved when projecting
mod4_clamp <- maxent(x = pder[,selected_vars], p = pa, path = paste0("C:/Users/User/Documents/carob1/output/maxent_outputs4_clamp"), 
                     args = prepPara(userfeatures = "LQ", betamultiplier = 1, 
                                     doclamp = TRUE, projectionlayers = "/Users/iel82user/Google Drive/1_osu_lab/projects/2017_7_workshop_enm_R/data/bioclim"))

mod4_noclamp <- maxent(x = pder[c(,selected_vars)], p = pa, 
                       path = paste0("C:/Users/User/Documents/carob1/output/maxent_outputs4_noclamp"), 
                       args = prepPara(userfeatures = "LQ",
                                       betamultiplier = 1, doclamp = FALSE, projectionlayers = "/Users/iel82user/Google Drive/1_osu_lab/projects/2017_7_workshop_enm_R/data/bioclim"))

ped_clamp <- raster(paste0("C:/Users/User/Documents/carob1/output/maxent_outputs4_clamp/species_bioclim.asc"))
ped_noclamp <- raster(paste0("C:/Users/User/Documents/carob1/output/maxent_outputs4_noclamp/species_bioclim.asc"))
plot(stack(ped_clamp, ped_noclamp))

## we may notice small differences, especially clamp shows
## higher predictions in most areas.
###4.5 Cross validation

#####Thread 25

mod4_cross <- maxent(x=pder[,selected_vars], p=pa, 
                     path=paste0("C:/Users/User/Documents/carob1/output/maxent_outputs4_cross"), 
                     args=prepPara(userfeatures="LQ",
                                   betamultiplier=1,
                                   doclamp = TRUE,
                                   projectionlayers="/Users/iel82user/Google Drive/1_osu_lab/projects/2017_7_workshop_enm_R/data/bioclim",
                                   replicates=5, ## 5 replicates
                                   replicatetype="crossvalidate") )
##possible values are: crossvalidate,bootstrap,subsample