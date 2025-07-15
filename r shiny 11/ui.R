library(shiny)
library(shinydashboard)
library(plotly)

dashboardPage(
  skin = NULL,
  dashboardHeader(
    title = ("Deforestasi Kalimantan"),
    tags$li(class = "dropdown",
            tags$style(HTML(".main-header .navbar { background-color: #2e7d32 !important;}"))
    )
  ),
  
  dashboardSidebar( width = 280,
                    sidebarMenu(id = "tabs",
                                menuItem("Dashboard", tabName = "dash", icon = icon("tree")),
                                menuItem("Eksplorasi & Analisis", icon = icon("layer-group"),
                                         menuSubItem("Peta Deforestasi", tabName = "peta", icon = icon("map")),
                                         menuSubItem("Peta Emisi Karbon Bruto", tabName = "peta2", icon = icon("map")),
                                         menuSubItem("Regresi Penyebab Deforestasi", tabName = "regresi_penyebab", icon = icon("line-chart")),
                                         menuSubItem("Regresi Dampak Deforestasi", tabName = "regresi_dampak", icon = icon("line-chart"))
                                ),
                                menuItem("Unduh Data", icon = icon("download"),
                                         menuSubItem("Data Deforestasi", tabName = "unduh", icon = icon("file-download")),
                                         menuSubItem("Data Emisi Karbon Bruto", tabName = "unduh2", icon = icon("file-download"))
                                ),
                                menuItem("Tentang", tabName = "about", icon = icon("info-circle"))
                    )
  ),
  
  dashboardBody(
    tags$head(
      tags$link(
        href = "https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap",
        rel = "stylesheet"
      ),
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css")),
    
    tabItems(
      tabItem(tabName = "dash",
              # Filter Pilih Provinsi
              selectInput(
                inputId  = "prov",
                label    = "Pilih Provinsi:",
                choices  = c("ALL", levels(data$Provinsi)),
                selected = "ALL",
                width = "1200px"
              ),
              fluidRow(
                valueBoxOutput("main_driver", width = 4),
                valueBoxOutput("avg_loss", width = 4),
                valueBoxOutput("max_loss_year", width = 4)
              ),
              
              
              fluidRow(
                column(width=6,
                       box(title="Total Deforestasi (ha)", style = "height: 625px",
                           width=NULL, solidHeader=TRUE, status="success",
                           plotlyOutput("treeLossPlot", height="375px"),
                           br(),
                           uiOutput("interpretasi_linechart")  # Output interpretasi
                       )
                ),
                column(width=6,
                       box(title="Deforestasi Berdasarkan Penyebab", style = "height: 625px",
                           width=NULL, solidHeader=TRUE, status="success",
                           selectInput("tahun",
                                       "Pilih Tahun:",
                                       choices = c("ALL", sort(unique(data$Tahun))),
                                       selected = "ALL"
                           ),
                           plotlyOutput("driverLossPie", height = "300px"),
                           br(),
                           uiOutput("interpretasi_piechart") # interpretasi pie chart
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
                    leafletOutput("treeMap", height = 800)
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
                  ),
                  # Interpretasi Interaktif
                  fluidRow(
                    box(
                      title = "Interpretasi",
                      width = 12,
                      solidHeader = TRUE,
                      status = "success",
                      htmlOutput("interpretasi_peta")  # Output dari server
                    )
                  )
                )
              )
      ),
      tabItem(tabName = "peta2",
              fluidRow(
                column(
                  width = 8,
                  box(
                    title = "Peta Emisi Karbon Bruto Akibat Deforestasi Kalimantan per Provinsi",
                    width = NULL, solidHeader = TRUE, status = "success",
                    leafletOutput("carbonMap", height = 875)
                  )
                ),
                column(
                  width = 4,
                  box(
                    title = "Filter Tahun",
                    width = NULL, solidHeader = TRUE, status = "warning",
                    selectInput("tahun_peta_karbon",
                                "Pilih Tahun:",
                                choices = c("ALL", sort(unique(data$Tahun))),
                                selected = "ALL")
                  ),
                  box(
                    title = "Rekap Emisi Karbon Bruto (ton)",
                    width = NULL, solidHeader = TRUE, status = "primary",
                    DT::dataTableOutput("grossTable")
                  ),
                  # Interpretasi Interaktif
                  fluidRow(
                    box(
                      title = "Interpretasi",
                      width = 12,
                      solidHeader = TRUE,
                      status = "success",
                      htmlOutput("interpretasi_peta2")  # Output dari server
                    )
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
      tabItem(tabName = "regresi_dampak",
              fluidRow(
                box(
                  title = "Analisis Dampak Deforestasi terhadap Emisi Karbon",
                  width = 12, solidHeader = TRUE, status = "success",
                  numericInput("tree_loss_input", "Kehilangan Tutupan Pohon (ribu ha):", value = NA),
                  actionButton("predict_dampak", "Prediksi Emisi Karbon", icon = icon("calculator")),
                  tags$div(textOutput("hasil_prediksi_dampak"), class = "prediksi-text"),
                  tags$hr(),
                  plotOutput("plot_regresi_dampak", height = "400px")
                )
              )
      ),
      
      
      tabItem(tabName = "unduh",
              fluidRow(
                box(
                  title = "Tabel Data Regresi Penyebab Deforestasi",
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
                  downloadButton("unduh_data_regresi", "Download Data Regresi Penyebab (.xlsx)")
                )
              )
      ),
      tabItem(tabName = "unduh2",
              fluidRow(
                box(
                  title = "Tabel Data Regresi Dampak Deforestasi",
                  width = 12,
                  solidHeader = TRUE,
                  status = "primary",
                  DT::dataTableOutput("tabel_dampak2")
                )
              ),
              fluidRow(
                box(
                  title = "Unduh Data",
                  width = 12,
                  solidHeader = TRUE,
                  status = "primary",
                  downloadButton("unduh_data_dampak", "Download Data Regresi Dampak (.xlsx)")
                )
              )
      ),
      
      tabItem(tabName = "about", 
              div(class = "about-header",
                  tags$div(
                    h1("Tentang", style = "font-weight: bold; font-size: 30px; margin-bottom: 5px; margin-top: 35px;"),
                    h1("Dashboard Deforestasi Kalimantan", style = "font-size: 18px; margin-top: 0px;"),
                    style = "text-align: justify;"
                  )
              ),
              
              br(),
              tabsetPanel(type = "tabs", id = "about_tabs",
                          tabPanel("Ringkasan",
                                   br(),
                                   style = "text-align: justify;",
                                   p(tags$b("Deforestasi"), " merupakan hilangnya hutan secara permanen akibat aktivitas manusia, 
                                     seperti pembukaan lahan, kebakaran hutan, logging, pembangunan infrastruktur, maupun karena faktor alam. 
                                     Dampaknya tidak hanya terhadap kerusakan lingkungan, tetapi juga berdampak langsung pada keberlanjutan kehidupan manusia, satwa, dan iklim."),
                                   
                                   p(tags$b("Dashboard"),"ini dikembangkan sebagai bagian dari Tugas Akhir Mata Kuliah Komputasi Statistik.
                                    Tujuan utamanya adalah menyediakan media interaktif untuk mengeksplorasi isu lingkungan terkhusus deforestasi di Pulau Kalimantan secara komprehensif dan kuantitatif.
                                    Dengan pendekatan visual dan analisis statistik, pengguna dapat memahami dinamika kehilangan tutupan hutan serta emisi karbon yang dihasilkan."),
                                   
                                   p(tags$b("Fitur Utama")," dalam dashboard ini meliputi:"),
                                   tags$ul(
                                     tags$li("Visualisasi tren deforestasi dari tahun 2015 hingga 2024 dalam bentuk grafik garis,"),
                                     tags$li("Komposisi penyebab deforestasi dalam bentuk diagram lingkaran,"),
                                     tags$li("Sebaran spasial deforestasi berdasarkan provinsi dalam bentuk peta interaktif,"),
                                     tags$li("Sebaran spasial emisi karbon bruto berdasarkan provinsi dalam bentuk peta interaktif,"),
                                     tags$li("Analisis regresi penyebab deforestasi dengan variabel bebas: jumlah alih lahan, kebakaran hutan, dan logging,"),
                                     tags$li("Analisis regresi dampak deforestasi dengan variabel bebas kehilangan tutupan pohon dan variabel respon emisi karbon bruto,"),
                                     tags$li("Fitur unduh data regresi baik penyebab maupun dampak deforestasi dalam format Excel.")
                                   ),
                                   
                                   p("Melalui dashboard ini, diharapkan pengguna—baik akademisi, mahasiswa, maupun pengambil kebijakan—dapat memperoleh wawasan yang lebih tajam terhadap permasalahan deforestasi. 
                                     Tidak hanya sebagai alat visualisasi, tetapi juga sebagai sarana pendukung pengambilan keputusan berbasis data dan bukti ilmiah.",
                                     style = "text-align: justify;")
                          ),
                          
                          tabPanel("Analisis Statistik", 
                                   br(), 
                                   style = "text-align: justify;", 
                                   p("Dashboard ini menggunakan dua pendekatan statistik utama untuk menganalisis deforestasi di Kalimantan, yaitu regresi panel dan regresi linier sederhana. 
                                      Tujuan utamanya adalah mengidentifikasi penyebab utama kehilangan tutupan hutan serta mengukur dampaknya terhadap emisi karbon bruto."),
                                   
                                   tags$ul(
                                     tags$li(
                                       tags$b("Regresi Panel: Penyebab Deforestasi"),
                                       
                                       p("Model regresi panel digunakan karena data deforestasi tersusun dalam format panel, yaitu terdiri dari observasi yang berulang pada beberapa provinsi selama periode waktu tertentu. 
                                          Pendekatan ini memungkinkan pengendalian terhadap heterogenitas tidak teramati antar provinsi, serta menangkap dinamika temporal yang berpotensi memengaruhi deforestasi. 
                                          Dengan demikian, regresi panel memberikan estimasi parameter yang lebih efisien dan robust dibanding regresi biasa ketika data memiliki struktur longitudinal."),
                                       
                                       p("Model regresi panel untuk Tree Cover Loss:"),
                                       withMathJax("$$\\text{Tree Cover Loss}_{it} = \\beta_0 + \\beta_1 (\\text{Alih Lahan}_{it}) + \\beta_2 (\\text{Kebakaran}_{it}) + \\beta_3 (\\text{Logging}_{it}) + u_i + \\epsilon_{it}$$"),
                                       p("Keterangan: \\(i\\) menyatakan provinsi dan \\(t\\) menyatakan tahun."),
                                       
                                       p("Ringkasan hasil model:"),
                                       verbatimTextOutput("summary_regresi_penyebab"),
                                       
                                       p(tags$b("Interpretasi:")),
                                       p("Hasil regresi panel menunjukkan bahwa ketiga variabel bebas—alih lahan, kebakaran, dan logging—memiliki pengaruh yang signifikan terhadap kehilangan tutupan hutan, 
                                          ditunjukkan oleh nilai p-value yang lebih kecil dari 0,05."),
                                       p("Koefisien determinasi \\( R^2 \\) sebesar 0,99954 menunjukkan bahwa model mampu menjelaskan sekitar 99,95% variasi kehilangan tutupan hutan. 
                                          Ini mengindikasikan bahwa model sangat baik dalam menjelaskan hubungan antara variabel-variabel penyebab dan kehilangan hutan. Nilai Adjusted \\( R^2 \\) sebesar 0,99951 tetap sangat tinggi, menunjukkan bahwa model tetap efisien bahkan setelah memperhitungkan jumlah variabel prediktor."),
                                       
                                       p(tags$b("Persamaan Regresi Panel:")),
                                       p(withMathJax("$$\\widehat{\\text{Tree Cover Loss}} = 1{,}595 + 1{,}0258 \\cdot \\text{Alih Lahan} + 1{,}0129 \\cdot \\text{Kebakaran} + 1{,}1585 \\cdot \\text{Logging}$$")),
                                     ),
                                     br(),
                                     tags$li(
                                       tags$b("Regresi Linier Sederhana: Dampak Deforestasi"),
                                       
                                       p("Model regresi linier sederhana digunakan untuk menganalisis hubungan antara kehilangan tutupan hutan dan emisi karbon bruto karena hanya ada satu variabel prediktor dan tujuan analisisnya adalah untuk mengetahui kekuatan serta arah hubungan linear."),
                                       
                                       p("Model regresi linier sederhana untuk Gross Carbon Emission:"),
                                       withMathJax("$$\\text{Gross Carbon Emission} = \\alpha_0 + \\alpha_1 (\\text{Tree Cover Loss}) + \\epsilon$$"),
                                       
                                       p("Ringkasan hasil model:"),
                                       verbatimTextOutput("summary_regresi_dampak"),
                                       
                                       p(tags$b("Interpretasi:")),
                                       p("Hasil regresi menunjukkan bahwa kehilangan tutupan pohon secara signifikan memengaruhi emisi karbon bruto, dibuktikan dengan nilai p-value sebesar 0,002 yang lebih kecil dari 0,05."),
                                       p("Nilai koefisien determinasi \\( R^2 \\) sebesar 0,7156 menunjukkan bahwa sekitar 71,56% variasi emisi karbon bruto dapat dijelaskan oleh kehilangan tutupan pohon. Nilai Adjusted \\( R^2 \\) sebesar 0,6801 mengindikasikan bahwa model cukup baik meskipun hanya menggunakan satu variabel prediktor."),
                                       p(tags$b("Persamaan Regresi Linier:")),
                                       p(withMathJax("$$\\widehat{\\text{Gross Carbon Emission}} = 98{,}49 + 0{,}039 \\cdot \\text{Tree Cover Loss}$$")),
                                     )
                                   ),
                                   div(style = "text-align: right;",
                                       downloadButton("unduh_pdf", "Download Analisis Lengkap (.pdf)")
                                   )
                          ),
                          
                          tabPanel("Sumber", 
                                   br(),
                                   div(class = "source-box",
                                       img(src = "gfw.png"),
                                       div(class = "source-text",
                                           h4("Global Forest Watch (GFW)"),
                                           tags$a(href = "https://www.globalforestwatch.org", "https://www.globalforestwatch.org"), 
                                           p("GFW adalah platform global yang menyediakan data pemantauan hutan berbasis satelit secara real-time. Dalam dashboard ini, data kehilangan tutupan pohon serta emisi karbon murni diperoleh dari basis data GFW."),
                                       )
                                   ),
                                   
                                   div(class = "source-box",
                                       img(src = "bps.png"),
                                       div(class = "source-text",
                                           h4("Badan Pusat Statistik (BPS)"),
                                           tags$a(href = "https://www.bps.go.id","https://www.bps.go.id"), 
                                           p("BPS adalah lembaga pemerintah setara kementerian di Indonesia yang bertanggung jawab dalam penyediaan data statistik nasional. Beberapa indikator sosial ekonomi seperti IPM, jumlah penduduk, dan produksi kayu diambil dari sumber ini sebagai bagian dari variabel analisis.")
                                       )
                                   ),
                                   div(class = "source-box",
                                       img(src = "copernicus.png"),
                                       div(class = "source-text",
                                           h4("Copernicus Climate Data Store"),
                                           tags$a(href = "https://cds.climate.copernicus.eu", "https://cds.climate.copernicus.eu"), 
                                           p("Copernicus adalah program pengamatan Bumi milik Uni Eropa, yang menyediakan data dan layanan lingkungan secara terbuka. Data suhu dan curah hujan Kalimantan dalam periode 2015–2024 pada dashboard ini bersumber dari CDS.")
                                          
                                       )
                                   ),
                                   div(class = "source-box",
                                       img(src = "github.png"),
                                       div(class = "source-text",
                                           h4("Git-Hub : ans-4175 (Ahmad Anshorimuslim Syuhada)"),
                                           tags$a(href = "https://github.com/ans-4175/peta-indonesia-geojson", "https://github.com/ans-4175/peta-indonesia-geojson"), 
                                           p("Repositori GitHub ini menyediakan data spasial Indonesia dalam format GeoJSON. File ini digunakan untuk membangun peta interaktif di dashboard, khususnya untuk menampilkan wilayah Kalimantan."),
                                           
                                       )
                                   )
                          ),

                          
                          tabPanel("Data Lainnya",
                                   br(),
                                   style = "text-align: justify;",
                                   fluidRow(
                                     column(6,
                                            p("Data pada bagian ini merupakan data tambahan yang telah kami olah dari berbagai sumber, seperti Copernicus Climate Data Store dan Badan Pusat Statistik (BPS). Data ini mencakup variabel suhu, curah hujan, Indeks Pembangunan Manusia (IPM), jumlah penduduk, serta produksi kayu di provinsi Kalimantan."),
                                            p("Meskipun telah dilakukan eksplorasi dan pengujian, variabel-variabel ini tidak menunjukkan signifikansi statistik saat dimasukkan ke dalam model analisis regresi. Bahkan, penyertaannya justru menurunkan nilai Adjusted R². Hal ini mengindikasikan bahwa model menjadi kurang baik dalam menjelaskan variasi data. 
                                              Oleh karena itu, data ini tidak digunakan dalam model utama pada dashboard. Namun, agar tidak terbuang percuma dan tetap dapat memberikan manfaat, data ini tetap kami cantumkan dan sediakan dalam bentuk file unduhan."),
                                            p("Harapannya, pengguna lain dapat memanfaatkan data ini untuk keperluan analisis lanjutan, eksplorasi, atau penelitian lebih lanjut sesuai kebutuhan masing-masing.")
                                            
                                            ),
                                     column(6,
                                            div(class = "source-box",
                                                img(src = "copernicus.png"),
                                                div(class = "source-text",
                                                    h4("Data Iklim: Copernicus Climate Data Store"),
                                                    br(),
                                                    p("Data Suhu Pulau Kalimantan Tahun 2015-2024"),
                                                    downloadButton("unduh_data_suhu", "Download Data Suhu (.xlsx)"),
                                                    tags$style("#unduh_data_suhu { text-decoration: none !important; }"),
                                                    br(),
                                                    p("Data Curah Hujan Kalimantan per Provinsi Tahun 2015-2024"),
                                                    downloadButton("unduh_data_curah_hujan", "Download Curah Hujan (.xlsx)"),
                                                    tags$style("#unduh_data_curah_hujan { text-decoration: none !important; }"),
                                                )
                                            ),
                                            div(class = "source-box",
                                                img(src = "bps.png"),
                                                div(class = "source-text",
                                                    h4("Data Sosial Ekonomi: Badan Pusat Statistik (BPS)"),
                                                    br(),
                                                    p("Data IPM, Jumlah Penduduk, dan Produksi Kayu Kalimantan per Provinsi Tahun 2015-2024."),
                                                    downloadButton("unduh_data_bps", "Download Data Sosial Ekonomi (.xlsx)"),
                                                    tags$style("#unduh_data_bps { text-decoration: none !important; }")
                                                )
                                            )
                                     )
                                   )
                          ),
                          tabPanel("Panduan Pengguna",
                                   fluidRow(
                                     column(width = 6,
                                            div(style = "display: flex; justify-content: center;",
                                                tags$iframe(
                                                  width = "100%", height = "300",
                                                  src = "https://www.youtube.com/embed/a7mAGoJG3PE",
                                                  title = "Panduan Pengguna Dashboard",
                                                  frameborder = "0",
                                                  allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
                                                  allowfullscreen = NA
                                                )
                                            )
                                     ),
                                     
                                     column(width = 6,
                                            div(style = "padding: 10px 20px; text-align: justify;",
                                                p("Video di samping merupakan panduan singkat untuk memandu pengguna dalam menjelajahi fitur-fitur yang tersedia di dashboard Deforestasi Kalimantan."),
                                                p("Diharapkan dengan panduan ini, pengguna dapat memahami cara kerja dashboard dan memperoleh wawasan data secara maksimal."),
                                                p("Terima Kasih <3")
                                            )
                                     )
                                   )
                          ),
                          
                          tabPanel("Metadata",
                                   fluidPage(
                                     tags$div(style = "padding: 7px; font-family: 'Poppins', sans-serif;text-align: justify;",
                                              
                                              tags$h5("Apa Itu Metadata?", style = "margin-bottom: 10px;"),
                                              tags$p("Metadata adalah informasi deskriptif tentang data. Dalam konteks dashboard ini, metadata menjelaskan sumber data, definisi variabel, metode analisis, dan format file yang digunakan. Tujuannya adalah untuk membantu pengguna memahami konteks dan isi data secara menyeluruh."),
                                     
                                              tags$h5("1. Informasi Umum", style = "font-weight: bold; margin-top: 20px;"),
                                              tags$ul(
                                                tags$li(tags$b("Judul Dasboard:"), "Deforestasi Kalimantan"),
                                                tags$li(tags$b("Bahasa Pengembangan:"), " R"),
                                                tags$li(tags$b("Aplikasi Pengembangan:"), " R dan R-Studio"),
                                                tags$li(tags$b("Versi Aplikasi:"), " 4.3.3"),
                                                tags$li(tags$b("Tanggal Rilis Dasboard:"), " 11 Juli 2025"),
                                                tags$li(tags$b("Pengembang:"), " Kelompok 5 Kelas 2KS3")
                                              ),
                                              
                                              tags$h5("2. Sumber Data", style = "font-weight: bold; margin-top: 20px;"),
                                              tags$ul(
                                                tags$li(tags$b("Global Forest Watch (GFW):"), " Data kehilangan tutupan pohon dan emisi karbon bruto"),
                                                tags$li(tags$b("Badan Pusat Statistik (BPS):"), " Data sosial ekonomi (IPM, penduduk, produksi kayu)"),
                                                tags$li(tags$b("Copernicus CDS:"), " Data suhu dan curah hujan Kalimantan"),
                                                tags$li(tags$b("GitHub ans-4175:"), " Data spasial geojson batas provinsi Indonesia")
                                              ),
                                              
                                              tags$h5("3. Cakupan Data", style = "font-weight: bold; margin-top: 20px;"),
                                              tags$ul(
                                                tags$li(tags$b("Wilayah:"), " Kalimantan (5 provinsi)"),
                                                tags$li(tags$b("Periode Waktu:"), " 2015–2024")
                                              ),
                                              
                                              tags$h5("4. Definisi Variabel", style = "font-weight: bold; margin-top: 20px;"),
                                              p("Berikut daftar variabel yang digunakan dalam dashboard beserta penjelasannya untuk memudahkan interpretasi."),
                                              tags$table(class = "table table-bordered",
                                                         tags$thead(
                                                           tags$tr(
                                                             tags$th("Variabel"), 
                                                             tags$th("Definisi")
                                                           )
                                                         ),
                                                         tags$tbody(
                                                           style = "text-align: left;",
                                                           tags$tr(tags$td("Tree cover loss"), 
                                                                   tags$td("Menggambarkan total luas hutan yang hilang dalam satu tahun tertentu akibat berbagai aktivitas, dinyatakan dalam hektar.")),
                                                           tags$tr(tags$td("Gross carbon"), 
                                                                   tags$td("Total emisi karbon bruto yang dilepaskan ke atmosfer akibat kehilangan tutupan pohon, diukur dalam Megagram (ton metrik).")),
                                                           tags$tr(tags$td("logging"), 
                                                                   tags$td("Aktivitas penebangan pohon untuk keperluan industri, pembangunan, atau penggunaan kayu lainnya. Satuan: ribu hektar.")),
                                                           tags$tr(tags$td("Jumlah alih lahan"), 
                                                                   tags$td("Konversi lahan hutan menjadi penggunaan lain seperti pertanian, perkebunan, atau pemukiman. Satuan: ribu hektar.")),
                                                           tags$tr(tags$td("wildfire"), 
                                                                   tags$td("Luas area hutan yang terbakar akibat kebakaran alami maupun buatan. Satuan: ribu hektar.")),
                                                           tags$tr(tags$td("suhu"), 
                                                                   tags$td("Suhu udara rata-rata tahunan di masing-masing provinsi Kalimantan (°C).")),
                                                           tags$tr(tags$td("curah hujan"), 
                                                                   tags$td("Total curah hujan tahunan di tiap provinsi Kalimantan, dalam milimeter (mm).")),
                                                           tags$tr(tags$td("IPM"), 
                                                                   tags$td("Indeks Pembangunan Manusia, mencakup dimensi pendidikan, kesehatan, dan standar hidup.")),
                                                           tags$tr(tags$td("jumlah penduduk"), 
                                                                   tags$td("Total populasi di tiap provinsi Kalimantan untuk setiap tahun pengamatan.")),
                                                           tags$tr(tags$td("produksi kayu"), 
                                                                   tags$td("Volume produksi kayu legal yang tercatat, mencerminkan kegiatan kehutanan di masing-masing provinsi."))
                                                         )
                                              ),
                                              
                                              tags$h5("5. Metodologi Analisis", style = "font-weight: bold; margin-top: 20px;"),
                                              tags$ul(
                                                tags$li(tags$b("Regresi Panel (Random Effect):"), " Untuk mengukur pengaruh logging, kebakaran, dan alih fungsi lahan terhadap deforestasi"),
                                                tags$li(tags$b("Regresi Linier Sederhana:"), " Untuk memodelkan hubungan antara kehilangan tutupan pohon dan emisi karbon bruto.")
                                              ),
                                              
                                              tags$h5("6. Catatan", style = "font-weight: bold; margin-top: 25px;"),
                                              p("Beberapa variabel tambahan seperti suhu, curah hujan, IPM, dan jumlah penduduk telah diuji dalam eksplorasi model namun tidak menunjukkan signifikansi statistik. 
                                                 Meski demikian, data tetap disediakan agar dapat digunakan untuk analisis lanjutan atau eksplorasi lainnya."),
                                              
                                              tags$h5("7. Informasi Akses & Format Unduhan Data Awal", style = "font-weight: bold; margin-top: 20px;"),
                                              tags$table(class = "table table-striped table-bordered",
                                                         tags$thead(
                                                           tags$tr(
                                                             tags$th("Sumber"), 
                                                             tags$th("Jenis Data"), 
                                                             tags$th("Format"), 
                                                             tags$th("Link Akses")
                                                           )
                                                         ),
                                                         tags$tbody(
                                                           tags$tr(
                                                             tags$td("Global Forest Watch (GFW)"),
                                                             tags$td("Kehilangan tutupan pohon & emisi karbon bruto"),
                                                             tags$td("Google Spreadsheet"),
                                                             tags$td(tags$a(href = "https://www.globalforestwatch.org", "Kunjungi GFW", target = "_blank"))
                                                           ),
                                                           tags$tr(
                                                             tags$td("Badan Pusat Statistik (BPS)"),
                                                             tags$td("IPM, Jumlah Penduduk, Produksi Kayu"),
                                                             tags$td(".xlsx"),
                                                             tags$td(tags$a(href = "https://www.bps.go.id", "Kunjungi BPS", target = "_blank"))
                                                           ),
                                                           tags$tr(
                                                             tags$td("Copernicus CDS"),
                                                             tags$td("Data suhu dan curah hujan Kalimantan"),
                                                             tags$td(".nc (NetCDF)"),
                                                             tags$td(tags$a(href = "https://cds.climate.copernicus.eu", "Kunjungi CDS", target = "_blank"))
                                                           ),
                                                           tags$tr(
                                                             tags$td("GitHub ans-4175"),
                                                             tags$td("GeoJSON batas provinsi Indonesia"),
                                                             tags$td(".geojson"),
                                                             tags$td(tags$a(href = "https://github.com/ans-4175/peta-indonesia-geojson", "Lihat Repo", target = "_blank"))
                                                           )
                                                         )
                                              ),
                                              tags$br(),
                                              tags$p("Keterangan Format File:", style = "font-weight: bold; margin-top: 15px;"),
                                              tags$ul(
                                                tags$li(tags$code(".nc (NetCDF):"), " Format file standar untuk data iklim atau atmosfer resolusi tinggi."),
                                                tags$li(tags$code(".geojson:"), " Format spasial untuk menyimpan data geografi dalam bentuk JSON.")
                                              ),
                                              
                                              # Penjelasan penggunaan data
                                              tags$p("Data dalam dashboard ini dimanfaatkan untuk analisis eksploratif dan pemodelan deforestasi di Kalimantan. 
                                                      Harap perhatikan bahwa meskipun data diperoleh dari sumber terpercaya, pengguna tetap disarankan untuk memverifikasi ulang jika digunakan untuk kebijakan atau publikasi resmi.
                                                      Pengguna diharapkan menggunakan data ini secara bijak sesuai dengan kebutuhan akademik, kebijakan, atau eksplorasi lanjutan.",
                                                     style = "margin-top: 15px; font-style: italic; font-size:14px"),
                                              
                                     )
                                   )
                          ),
                          tabPanel("Anggota Tim", 
                                   br(), 
                                   fluidRow(
                                     column(6,
                                            tags$img(src = "bertiga.jpg", 
                                                     style = "width: 100%; max-width: 100%; margin-left: 20px; border-radius: 15px;")
                                     ),
                                     column(6,
                                            div(
                                              style = "padding: 10px 30px 10px 10px; text-align: justify; font-family: 'Poppins', sans-serif;",
                                              p("Dashboard ini dikembangkan melalui kolaborasi tim yang mencakup proses pengumpulan data, analisis statistik, serta perancangan visualisasi dan antarmuka interaktif. Setiap anggota tim berkontribusi sesuai bidangnya, mulai dari pemodelan data hingga proses pengembangan, guna memastikan dashboard dapat digunakan secara informatif, fungsional, dan relevan untuk kebutuhan analisis deforestasi di Kalimantan.")
                                            )
                                     )
                                   ),
                                   br(),
                                   fluidRow(
                                     column(4,
                                            div(class = "team-card",
                                                tags$img(src = "arif.JPG"),
                                                div(class = "team-name", "Arif Budiman"),
                                                div(class = "team-role", "Pengembang utama dashboard, analisis data, dan desain tampilan (UI/UX)"),
                                                br(),
                                                div(class = "team-email", "222312994@stis.ac.id")
                                            )
                                     ),
                                     column(4,
                                            div(class = "team-card",
                                                tags$img(src = "aura.jpg"),
                                                div(class = "team-name", "Aura Hanifa Kasetya Putri"),
                                                div(class = "team-role", "Pembuatan grafik interaktif dan penulisan interpretasi visualisasi"),
                                                br(),
                                                div(class = "team-email", "222313003@stis.ac.id")
                                            )
                                     ),
                                     column(4,
                                            div(class = "team-card",
                                                tags$img(src = "arkillah.jpg"),
                                                div(class = "team-name", "M. Arkillah Ibnu A."),
                                                div(class = "team-role", "Pengumpulan data dan penelusuran sumber pendukung"),
                                                br(),
                                                div(class = "team-email", "222313191@stis.ac.id")
                                            )
                                     )
                                   )
                          )
                          
              )
      )
      
      
      
      
      
    )
  )
)