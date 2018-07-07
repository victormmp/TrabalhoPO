rm(list=ls())
library(readxl)
library(dplyr)
library(reshape2)

#Lendo dados
hpc <- read_excel("Desafio Bain/Q2/HPC.xlsx")
variations <- read_excel("Desafio Bain/Q2/Variations.xlsx")

NovoLucro <- function(CalculaHPC,BuscaVar,x)
{
  
  #Calcula lucro antigo da categoria
  lucro.atual = CalculaHPC$TotalProfit + CalculaHPC$ProfitCrossSellAsIs
  
  #Puxando variação 
  var.name = as.character(x)
  var.category = CalculaHPC$Exposure
  var = as.numeric(BuscaVar[which(BuscaVar$Exposure == var.category),var.name])
  
  #Calculando novo lucro da categoria por venda direta
  lucro.novo.VendaDireta = (1+var)*CalculaHPC$UnitsSold*CalculaHPC$UnitPrice*CalculaHPC$GrossMargin
  
  #Calculando novo lucro por cross-selling
  draw.update = as.numeric(BuscaVar[4,var.name])
  draw = CalculaHPC$CategoryDraw
  new.draw = draw + draw.update
  lucro.cross.selling = (new.draw/100)*CalculaHPC$Tickets*CalculaHPC$CrossSellAVGTicket*CalculaHPC$GrossMarginCrossSell
  
  #Calcula novo lucro
  novo.lucro = lucro.novo.VendaDireta + lucro.cross.selling
  
  return(novo.lucro-lucro.atual)
  
  
}

#Calculando lucro incremental p/ mudanças e categorias
lucroIncremental = matrix(0,nrow=12,ncol=9)
colnames(lucroIncremental) <- colnames(variations)[2:10]
row.names(lucroIncremental) <- hpc$Category

x <- seq(-2,2,0.5)

#Calculando variações
for(i in 1:nrow(lucroIncremental))
{
  for(j in 1:(ncol(lucroIncremental)))
  {
    lucroIncremental[i,j] <- NovoLucro(hpc[i,],variations,x[j])
  }
}

#Ajustando dados para ggplot
lucro.Incremental <- data.frame(Category = hpc$Category, lucroIncremental)
colnames(lucro.Incremental)[2:10] <- colnames(variations)[2:10]
lucro.Incremental <- melt(lucro.Incremental, id="Category")
lucro.Incremental$variable <- as.numeric(as.character(lucro.Incremental$variable))

#Gráfico de lucro incremental
ggplot(lucro.Incremental,aes(x=variable,y=value,colour=Category)) +
  geom_line(size=1) +  
  geom_point(size=2) +
  scale_x_continuous(name="Mudança no número de módulos expostos (# de módulos)") + 
  scale_y_continuous(name="Lucro incremental (R$)",
                     breaks=c(-35000,-20000,0,20000,35000)) + 
  labs(fill="Categorias") + 
  ggtitle("Lucro incremental por mudança de módulos expostos") +
  theme_minimal()

#Scatter plot lucro/módulo x cross-sell revenue
hpc <- mutate(hpc, LucroPorModulo = hpc$TotalProfit/hpc$ModulosAsIs)

shift <- c(2, 2, -1.5, 1, -2, 1.5, 1.5,-2,1,-1,-0.5,-1)
hpc <- mutate(hpc, MudancaModulos = shift)
hpc$MudancaModulos <- factor(hpc$MudancaModulos)

ggplot(hpc,aes(x=LucroPorModulo, y=RevenueCrossSellAsIs, colour = MudancaModulos)) + 
  geom_point(size=10,alpha=0.4) + 
  theme_minimal()

#Visualizando indcadores 
ind <- hpc[,c("Category","ProfitCrossSellperModule","SingleProfitperModule")]
colnames(ind)[2:3] <- c("Cross-sell","Venda direta")
ind <- mutate(ind, Total = `Cross-sell`+`Venda direta`)
ind <- melt(ind,id="Category")
ind$Category <- factor(ind$Category)

ggplot(ind,aes(x=Category,y=value,fill=variable)) +
  geom_bar(position="dodge",stat = "identity") +
  scale_x_discrete(name=NULL) + 
  scale_y_continuous(name="Lucro incremental (R$)",
                     breaks=seq(min(lucroIncremental),max(lucroIncremental),length.out=10)) + 
  labs(fill="Indicadores") + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Lucro incremental por alteração de produto")


#Calculando acréscimo no lucro
increase.idx <- matrix(0,nrow=12,ncol=9)
increase.idx[c(2,1),9] <- 1
increase.idx[c(7),8] <- 1
increase.idx[c(4,9),7] <- 1
increase.idx[6,6] <- 1
increase.profit <- sum(increase.idx*lucroIncremental)

decrease.idx <- matrix(0,nrow=12,ncol=9)
decrease.idx[c(8,5),1] <- 1
decrease.idx[11,4] <- 1
decrease.idx[3,2] <- 1
decrease.idx[c(10,12),3] <- 1
decrease.profit <- sum(decrease.idx*lucroIncremental)

increased.profit <- increase.profit + decrease.profit
print(paste("Increased profit = R$",round(increased.profit,2),sep=''))


#Lucro: R$66.9k
plus2.category <- c("Oral Hygiene", "Deodorants")
plut15.category <- c("Hair")
plus1.category <- c("Bath","Sun blockers")
plus05.category <- "Infant HPC"

minus15.category <- "Makeup"
minus2.category <- c("Skin", "Intimate Hygiene")
minus1.category <- c("Diapers", "Shaving")
minus05.category <- "Fragrance"




plus.profit <- sum((lucroIncremental[c(1,2),9])) + 
  sum(lucroIncremental[c(7,4),8]) + 
  lucroIncremental[9,7] +
  lucroIncremental[6,6]
minus.profit <- lucroIncremental[11,4] + sum(lucroIncremental[c(10,12),3]) + sum(lucroIncremental[c(3,8,5),1])
increased.profit <- minus.profit + plus.profit
print(paste("Increased profit = R$",round(increased.profit,2),sep=''))
