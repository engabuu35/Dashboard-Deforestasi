library(readxl)
library(dplyr)
library(writexl)
library(dplyr)
library(leaflet)
library(sf)
library(htmltools)
library(stringr)
library(plm)

data <- read_excel("./Data/deforestasi.xlsx")
data_reg <- read_excel("./Data/reg_sebab.xlsx")
geo_prov <- st_read("./Data/indonesia-prov.geojson")
data_akibat <- read_excel("./Data/regresi_akibat.xlsx")
data_suhu <- read_excel("./Data/suhu.xlsx")
data_hujan <- read_excel("./Data/hujan.xlsx")
data_bps <- read_excel("./Data/data_bps.xlsx")

if (!file.exists("Data/deforestasi.xlsx")) {
  stop("File data utama tidak ditemukan.")
}

if (!file.exists("Data/reg_sebab.xlsx")) {
  stop("File data utama tidak ditemukan.")
}

if (!file.exists("Data/indonesia-prov.geojson")) {
  stop("File data utama tidak ditemukan.")
}

if (!file.exists("Data/suhu.xlsx")) {
  stop("File data utama tidak ditemukan.")
}

if (!file.exists("Data/hujan.xlsx")) {
  stop("File data utama tidak ditemukan.")
}
if (!file.exists("Data/data_bps.xlsx")) {
  stop("File data utama tidak ditemukan.")
}

data <- data %>%
  rename(
    Driver = drivers_type,
    Tahun = loss_year,
    Tree_cover_loss = loss_area_ha,
    Gross_carbon = gross_carbon_emissions_Mg
  ) %>%
  mutate(
    Provinsi = factor(Provinsi, levels = c(
      "Kalimantan Utara", "Kalimantan Barat",
      "Kalimantan Selatan", "Kalimantan Timur", "Kalimantan Tengah"
    )),
    Driver = as.factor(Driver),
    Tahun = as.integer(Tahun)
  )

tahun_list <- 2015:2024

#===================================== Peta ==============================================#

geo_prov <- geo_prov %>%
  mutate(
    Propinsi = str_squish(Propinsi),  
    Propinsi = str_to_title(str_to_lower(Propinsi))
  )

# ambil hanya Kalimantan
kalimantan_geo <- geo_prov %>%
  filter(Propinsi %in% c(
    "Kalimantan Utara",
    "Kalimantan Barat",
    "Kalimantan Selatan",
    "Kalimantan Timur",
    "Kalimantan Tengah"
  )) %>%
  mutate(Provinsi = Propinsi)
# agregasi loss per provinsi
loss_by_prov <- data %>%
  group_by(Provinsi) %>%
  summarise(total_loss = sum(Tree_cover_loss, na.rm = TRUE))

# join ke geo
kalimantan_geo <- kalimantan_geo %>%
  left_join(loss_by_prov, by = "Provinsi")



#====================================== Regresi Sebab ==========================================#
# Regresi Peyebab Deforestasi
data_reg <- data_reg %>%
  rename(
    Tahun = loss_year,
    Y = loss_area_ribu_ha,
    X3 = logging_ribu_ha,
    X4 = Jumlah_alih_lahan_ribu_ha,
    X5 = wildfire_ribu_ha
  ) %>%
  mutate(
    across(
      .cols = c(Y, X3, X4, X5),
      .fns = ~ as.numeric(.)
    ),
    Provinsi = as.factor(Provinsi),
    Tahun = as.integer(Tahun)
  )

pdata <- pdata.frame(data_reg, index = c("Provinsi", "Tahun"))
formula_fe <- Y ~ X4 + X5 + X3
re_model <- plm(formula_fe, data = pdata, model = "random")

# =================== Regresi Dampak Deforestasi ===================


data_akibat <- data_akibat %>%
  rename(
    Tahun = loss_year,
    YY = gross_carbon_emissions_juta_Mg,
    XX = loss_area_ribu_ha
  ) %>%
  mutate(
    YY = as.numeric(YY),
    XX = as.numeric(XX)
  )

model_dampak <- lm(YY ~ XX, data = data_akibat)

