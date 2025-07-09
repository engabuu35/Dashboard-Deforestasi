library(shiny)
library(shinydashboard)
library(plotly)

dashboardPage(
  skin = NULL,
  dashboardHeader(
    title = span("Deforestasi Kalimantan",
                 style = "color:white; font-size:14px; font-weight:bold;"),
    tags$li(class = "dropdown",
            tags$style(HTML(".main-header .navbar { background-color: #2e7d32 !important; }"))
    )
  ),
  
  dashboardSidebar(
    sidebarMenu(id = "tabs",
                menuItem("Dashboard", tabName = "dash", icon = icon("dashboard")),
                menuItem("Peta", tabName = "peta", icon = icon("map")),
                menuItem("Regresi Penyebab Deforestasi", tabName = "regresi_penyebab", icon = icon("area-chart")),
                menuItem("Regresi Dampak Deforestasi", tabName = "regresi_dampak", icon = icon("area-chart")),
                menuItem("Sumber Data", tabName = "sumber", icon = icon("book")),
                menuItem("Unduh Data", tabName = "unduh", icon = icon("download"))
                
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$link(
        href = "https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap",
        rel = "stylesheet"
      ),
      tags$style(HTML("
  /* ===================== FONT & LAYOUT UMUM ===================== */
  body, .content-wrapper, .main-header .logo, .main-header .navbar, 
  .main-sidebar, .box, .box-header, .small-box, 
  h1, h2, h3, h4, h5, h6, label, input, select, button {
    font-family: 'Poppins', sans-serif !important;
  }

  /* ===================== WARNA UTAMA ===================== */
  :root {
  --gfw-green: #4C6C29;
  --gfw-dark-green: #658022;
  --gfw-cream: #F6F6F4;
  --gfw-neutral: #FFFFFF;
}

/* Font umum */
body, .content-wrapper, .main-header .logo, .main-header .navbar,
.main-sidebar, .box, .box-header, .small-box,
h1, h2, h3, h4, h5, h6, label, input, select, button {
  font-family: 'Poppins', sans-serif !important;
}

/* Header */
.main-header .navbar, .main-header .logo {
  background-color: var(--gfw-green) !important;
  color: var(--gfw-neutral) !important;
}
.main-header .logo {
  font-size: 18px !important;
  font-weight: bold;
}

/* Sidebar */
.skin-blue .main-sidebar {
  background-color: var(--gfw-green) !important;
}
.skin-blue .sidebar-menu > li > a {
  font-size: 13px !important;
  font-weight: 500;
  color: var(--gfw-neutral) !important;
}
.skin-blue .sidebar-menu > li.active > a,
.skin-blue .sidebar-menu > li:hover > a {
  background-color: var(--gfw-dark-green) !important;
  color: var(--gfw-neutral) !important;
}

/* Box */
.box {
  background-color: var(--gfw-cream) !important;
  border: none !important;
  border-radius: 6px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.05);
}
.box.box-solid > .box-header {
  background-color: var(--gfw-dark-green) !important;
  color: var(--gfw-neutral) !important;
  padding: 10px;
  border-radius: 6px 6px 0 0;
}
.box-title {
  font-size: 15px !important;
  font-weight: 600;
}

/* ValueBox */
.small-box {
  background-color: var(--gfw-cream) !important;
  color: #333 !important;
  border-radius: 6px;
  height: 120px !important;
  border-left: 4px solid var(--gfw-green);
}
.small-box .inner h3 {
  font-size: 22px !important;
  font-weight: bold;
}
.small-box .inner p {
  font-size: 14px !important;
}

/* Buttons */
.btn, .btn-default, .btn-primary {
  background-color: var(--gfw-green) !important;
  color: var(--gfw-neutral) !important;
  border: none !important;
  font-weight: 500;
}
.btn:hover {
  background-color: var(--gfw-dark-green) !important;
}

/* Inputs */
.form-control, .selectize-input {
  border: 1px solid #ccc !important;
  border-radius: 4px;
  font-size: 14px !important;
}

/* Table */
table.dataTable {
  background-color: var(--gfw-neutral) !important;
  font-size: 13px;
}
.dataTables_wrapper .dataTables_length,
.dataTables_wrapper .dataTables_filter,
.dataTables_wrapper .dataTables_info,
.dataTables_wrapper .dataTables_paginate {
  color: #444;
}

/* Teks khusus */
.prediksi-text {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  padding-top: 16px;
}

                      "))),
    
    tabItems(
      tabItem(tabName = "dash",
              fluidRow(
                valueBoxOutput("main_driver", width = 4),
                valueBoxOutput("avg_loss", width = 4),
                valueBoxOutput("max_loss_year", width = 4)
              ),
              
              
              fluidRow(
                column(width=6,
                       box(title="Total Tree Cover Loss (ha)",
                           width=NULL, solidHeader=TRUE, status="success",
                           selectInput(
                             inputId  = "prov",
                             label    = "Pilih Provinsi:",
                             choices  = c("ALL", levels(data$Provinsi)),
                             selected = "ALL"
                           ),
                           plotOutput("treeLossPlot", height="300px") # Tinggi sedikit dikurangi
                       )
                ),
                column(width=6,
                       box(title="Tree Cover Loss by Driver",
                           width=NULL, solidHeader=TRUE, status="success",
                           selectInput("tahun",
                                       "Pilih Tahun:",
                                       choices = c("ALL", sort(unique(data$Tahun))),
                                       selected = "ALL"
                           ),
                           plotlyOutput("driverLossPie", height = "300px") # Tinggi sedikit dikurangi
                       )
                )
              )
      ),
      
      tabItem(tabName = "peta",
              fluidRow(
                column(
                  width = 8,
                  box(
                    title = "Peta Deforestasi Kalimantan per Provinsi",
                    width = NULL, solidHeader = TRUE, status = "success",
                    leafletOutput("treeMap", height = 650)
                  )
                ),
                column(
                  width = 4,
                  box(
                    title = "Filter Tahun",
                    width = NULL, solidHeader = TRUE, status = "warning",
                    selectInput("tahun_peta",
                                "Pilih Tahun:",
                                choices = c("ALL", sort(unique(data$Tahun))),
                                selected = "ALL")
                  ),
                  box(
                    title = "Rekap Kehilangan (ha)",
                    width = NULL, solidHeader = TRUE, status = "primary",
                    DT::dataTableOutput("lossTable")
                  )
                )
              )
      ),
      
      # Tab untuk Regresi Penyebab Deforestasi
      tabItem(tabName = "regresi_penyebab",
              fluidRow(
                box(
                  title = "Analisis Regresi Penyebab Deforestasi",
                  width = 12, solidHeader = TRUE, status = "success",
                  fluidRow(
                    column(width = 4,
                           numericInput("alih_lahan", "Jumlah Alih Lahan (ribu ha):", value = NA)
                    ),
                    column(width = 4,
                           numericInput("kebakaran", "Kebakaran Hutan (ribu ha):", value = NA)
                    ),
                    column(width = 4,
                           numericInput("logging", "Logging (ribu ha):", value = NA)
                    )
                  ),
                  actionButton("regresi_btn", "Prediksi Deforestasi", icon = icon("calculator")),
                  tags$div(textOutput("prediksi_result"), class = "prediksi-text"),
                  tags$hr(),
                  plotOutput("regPlot", height = "400px")
                )
              )
              
      ),
      # Placeholder untuk "Regresi Dampak Deforestasi"
      tabItem(tabName = "regresi_dampak",
              h2("Konten Regresi Dampak Deforestasi Akan Ditempatkan Di Sini")
      ),
      
      tabItem(tabName = "sumber",
              fluidRow(
                box(
                  title = "Sumber Data",
                  width = 12,
                  solidHeader = TRUE,
                  status = "info",
                  HTML("
              <p>Aplikasi ini menggunakan data dari dua sumber utama:</p>
              <ol>
                <li>
                  <strong>Badan Pusat Statistik (BPS)</strong><br/>
                  <a href='https://www.bps.go.id' target='_blank'>https://www.bps.go.id</a>
                </li>
                <li>
                  <strong>Global Forest Watch (GFW)</strong><br/>
                  <a href='https://www.globalforestwatch.org' target='_blank'>https://www.globalforestwatch.org</a>
                </li>
              </ol>
              <hr/>
              <p>Data BPS digunakan untuk indikator sosial-ekonomi seperti jumlah penduduk, IPM, dan produksi kayu.</p>
              <p>Data dari Global Forest Watch digunakan untuk informasi spasial dan tahunan terkait kehilangan tutupan pohon.</p>
            ")
                )
              )
      ),
      tabItem(tabName = "unduh",
              fluidRow(
                box(
                  title = "Tabel Data Mentah",
                  width = 12,
                  solidHeader = TRUE,
                  status = "primary",
                  DT::dataTableOutput("tabel_data")
                )
              ),
              fluidRow(
                box(
                  title = "Unduh Data",
                  width = 12,
                  solidHeader = TRUE,
                  status = "primary",
                  downloadButton("unduh_data", "Download Data (.csv)")
                )
              )
      )
      
    )
  )
)